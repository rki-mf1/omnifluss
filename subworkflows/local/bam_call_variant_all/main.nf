include { LOFREQ_VITERBI }      from '../../../modules/nf-core/lofreq/viterbi/main'
include { LOFREQ_INDELQUAL }    from '../../../modules/nf-core/lofreq/indelqual/main'
include { LOFREQ_CALLPARALLEL } from '../../../modules/nf-core/lofreq/callparallel/main'
include { SAMTOOLS_INDEX }      from '../../../modules/nf-core/samtools/index/main'
include { BCFTOOLS_NORM }       from '../../../modules/nf-core/bcftools/norm/main'
include { BCFTOOLS_INDEX}       from '../../../modules/nf-core/bcftools/index/main'


workflow BAM_CALL_VARIANT_ALL {

    take:
    tools           // String
    ch_bam          // channel: [ val(meta), [ bam ]   ]
    ch_ref          // channel: [ val(meta), [ fasta ] ]
    ch_ref_index    // channel: [ val(meta), [ fai ]   ]


    main:
    ch_corrbam      = Channel.empty()
    ch_iqbam        = Channel.empty()
    ch_iqbam_bai    = Channel.empty()
    ch_vcf          = Channel.empty()
    ch_tbi          = Channel.empty()
    ch_versions     = Channel.empty()

    /****************************************************************/
    /* STEP 0: Format input Channels for sample-wise ordered tuples */
    /****************************************************************/
    ch_bam_cpy          = ch_bam.map{ meta, bam -> return [meta.id, meta, bam ] }
    ch_ref_cpy          = ch_ref.map{ meta, fasta -> return [meta.id, meta, fasta] }
    ch_ref_index_cpy    = ch_ref_index.map{ meta, fai -> return [meta.id, meta, fai] }

    ch_lofreq_viterbi_input = ch_bam_cpy.join(ch_ref_cpy).join(ch_ref_index_cpy)
        .multiMap{_sample_id, meta, bam, meta2, fasta, meta3, fai ->
            ch_bam: [meta, bam]
            ch_ref: [meta2, fasta]
            ch_ref_index: [meta3, fai]
        }

    if (tools.split(',').contains('lofreq')) {
        /****************************************************************/
        /* STEP 1: LOFREQ_VITERBI for mapping-error correction          */
        /****************************************************************/
        // LOFREQ_VITERBI nf-core module was implemented by @MarieLataretu and includes samtools sort. No need for an extra sorting step here.
        LOFREQ_VITERBI (
            ch_lofreq_viterbi_input.ch_bam,
            ch_lofreq_viterbi_input.ch_ref
        )
        ch_corrbam  = LOFREQ_VITERBI.out.bam
        ch_versions = ch_versions.mix(LOFREQ_VITERBI.out.versions.first())

        /*******************************************************************/
        /* STEP 2: LOFREQ_INDELQUAL adds indel qualities to the alignments */
        /*******************************************************************/
        ch_corrbam_cpy  = ch_corrbam.map{ meta, corrbam -> return [meta.id, meta, corrbam ] }

        ch_lofreq_indelqual_input = ch_corrbam_cpy.join(ch_ref_cpy)
            .multiMap{_sample_id, meta, corrbam, meta2, fasta ->
                ch_corrbam: [meta, corrbam]
                ch_ref: [meta2, fasta]
            }

        LOFREQ_INDELQUAL (
            ch_lofreq_indelqual_input.ch_corrbam,
            ch_lofreq_indelqual_input.ch_ref
        )
        ch_iqbam    = LOFREQ_INDELQUAL.out.bam
        ch_versions = ch_versions.mix(LOFREQ_INDELQUAL.out.versions.first())

        // LOFREQ_ALNQUAL adds alignment quality per base and indel
        // LOFREQ_ALNQUAL will not be taken over from FluPipe for now, as it is computed on the fly in lofreq call/call-parallel

        /*******************************************************************/
        /* STEP 3: SAMTOOLS_INDEX creates the bam index (bai)              */
        /*******************************************************************/
        SAMTOOLS_INDEX (
            ch_iqbam
        )
        ch_iqbam_bai    = SAMTOOLS_INDEX.out.bai    // [ val(meta), path("*.bai") ]
        ch_versions     = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

        /*******************************************************************/
        /* STEP 4: LOFREQ_CALLPARALLEL does the actual variant calling     */
        /*******************************************************************/
        ch_iqbam_cpy        = ch_iqbam.map{ meta, iqbam -> return [meta.id, meta, iqbam ] }
        ch_iqbam_bai_cpy    = ch_iqbam_bai.map{ meta, iqbai -> return [meta.id, meta, iqbai ] }

        ch_lofreq_callparallel_input = ch_iqbam_cpy.join(ch_iqbam_bai_cpy).join(ch_ref_cpy).join(ch_ref_index_cpy)
            .multiMap{ _sample_id, meta, iqbam, _meta2, iqbai, meta3, fasta, meta4, fai ->
                ch_input_sample: [meta, iqbam, iqbai, [] ]  // needs empty optional parameter here
                ch_ref: [meta3, fasta]
                ch_ref_index: [meta4, fai]
            }

        LOFREQ_CALLPARALLEL (
            ch_lofreq_callparallel_input.ch_input_sample,
            ch_lofreq_callparallel_input.ch_ref,
            ch_lofreq_callparallel_input.ch_ref_index
        )
        ch_vcf      = LOFREQ_CALLPARALLEL.out.vcf
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())
    }

    /*******************************************************************/
    /* STEP 5: Caller-independent postprocessing                       */
    /* STEP 5: BCFTOOLS_INDEX createse an index of the VCF file        */
    /*******************************************************************/
    BCFTOOLS_INDEX (
        ch_vcf
    )
    ch_tbi      = BCFTOOLS_INDEX.out.tbi
    ch_versions = ch_versions.mix(BCFTOOLS_INDEX.out.versions.first())

    /**********************************************************************/
    /* STEP 6: BCFTOOLS_NORM normalizes variant notations and positioning */
    /**********************************************************************/
    ch_vcf_cpy = ch_vcf.map{ meta, vcf -> return [meta.id, meta, vcf ] }
    ch_tbi_cpy = ch_tbi.map{ meta, tbi -> return [meta.id, meta, tbi ] }

    ch_bcftools_norm_input = ch_vcf_cpy.join(ch_tbi_cpy).join(ch_ref_cpy)
        .multiMap{_sample_id, meta, vcf, _meta2, tbi, meta3, fasta ->
            ch_input_variants: [meta, vcf, tbi]
            ch_ref: [meta3, fasta]
        }

    // Normalize variant notations and positioning; index normed VCF
    BCFTOOLS_NORM(
        ch_bcftools_norm_input.ch_input_variants,
        ch_bcftools_norm_input.ch_ref
    )
    ch_vcf      = BCFTOOLS_NORM.out.vcf     // overwrite VCF with VCF after normalization
    ch_tbi      = BCFTOOLS_NORM.out.tbi     // overwrite TBI with TBI after normalization
    ch_versions = ch_versions.mix(BCFTOOLS_NORM.out.versions.first())


    emit:
    bam         = ch_iqbam      // channel: [ val(meta), [ bam ] ]  // Not the same as input bam! Here, the bam got normalized and annotated.
    bai         = ch_iqbam_bai  // channel: [ val(meta), [ bai ] ]
    vcf         = ch_vcf        // channel: [ val(meta), [ vcf ] ]
    tbi         = ch_tbi        // channel: [ val(meta), [ tbi ] ]
    versions    = ch_versions   // channel: [ versions.yml ]
}

