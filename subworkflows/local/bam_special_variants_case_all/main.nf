
include { LOFREQ_CALLPARALLEL as LOFREQ_CALLPARALLEL_SPEC_CASE }    from '../../../modules/nf-core/lofreq/callparallel/main'
include { LOFREQ_FILTER }                                           from '../../../modules/nf-core/lofreq/filter/main'
include { INV_RESCUE_VARIANTS_PYTHON }                              from '../../../modules/local/inv_rescue_variants_python/main'


workflow BAM_SPECIAL_VARIANTS_CASE_ALL {

    take:
    ch_iqbam        // channel: [ val(meta), [ bam ]   ]
    ch_iqbam_bai    // channel: [ val(meta), [ bai ]   ]
    ch_ref          // channel: [ val(meta), [ fasta ] ]
    ch_ref_index    // channel: [ val(meta), [ fai ]   ]


    main:
    ch_vcf      = Channel.empty()
    ch_bed      = Channel.empty()
    ch_versions = Channel.empty()

    /****************************************************************/
    /* STEP 0: Format input Channels for LOFREQ_CALLPARALLEL        */
    /****************************************************************/
    ch_iqbam_cpy        = ch_iqbam.map{ meta, iqbam -> return [meta.id, meta, iqbam ] }
    ch_iqbam_bai_cpy    = ch_iqbam_bai.map{ meta, iqbai -> return [meta.id, meta, iqbai ] }
    ch_ref_cpy          = ch_ref.map{ meta, fasta -> return [meta.id, meta, fasta] }
    ch_ref_index_cpy    = ch_ref_index.map{ meta, fai -> return [meta.id, meta, fai] }

    ch_lofreq_callparallel_input = ch_iqbam_cpy.join(ch_iqbam_bai_cpy).join(ch_ref_cpy).join(ch_ref_index_cpy)
        .multiMap{ _sample_id, meta, iqbam, _meta2, iqbai, meta3, fasta, meta4, fai ->
            ch_input_sample: [meta, iqbam, iqbai, [] ]  // needs empty optional parameter here
            ch_ref: [meta3, fasta]
            ch_ref_index: [meta4, fai]
            }

    /*******************************************************************/
    /* STEP 1: LOFREQ_CALLPARALLEL variant calling                     */
    /*******************************************************************/
    LOFREQ_CALLPARALLEL_SPEC_CASE (
        ch_lofreq_callparallel_input.ch_input_sample,
        ch_lofreq_callparallel_input.ch_ref,
        ch_lofreq_callparallel_input.ch_ref_index
    )
    ch_versions = ch_versions.mix(LOFREQ_CALLPARALLEL_SPEC_CASE.out.versions.first())

    /*******************************************************************/
    /* STEP 2: LOFREQ_FILTER filters the variant set; see config       */
    /*******************************************************************/
    LOFREQ_FILTER (
        LOFREQ_CALLPARALLEL_SPEC_CASE.out.vcf
    )
    ch_vcf      = LOFREQ_FILTER.out.vcf
    ch_versions = ch_versions.mix(LOFREQ_FILTER.out.versions.first())

    /***************************************************************************************************************/
    /* STEP 3: INV_RESCUE_VARIANTS_PYTHON generates a bed file with HQ variant sites to be masked in the consensus */
    /***************************************************************************************************************/
    INV_RESCUE_VARIANTS_PYTHON (
        ch_vcf
    )
    ch_bed      = INV_RESCUE_VARIANTS_PYTHON.out.bed
    ch_versions = ch_versions.mix(INV_RESCUE_VARIANTS_PYTHON.out.versions.first())


    emit:
    vcf      = ch_vcf       // channel: [ val(meta), [ vcf ] ]
    bed      = ch_bed       // channel: [ val(meta), [ bed ] ]
    versions = ch_versions  // channel: [ versions.yml ]
}

