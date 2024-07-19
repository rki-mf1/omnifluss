include { LOFREQ_VITERBI }      from '../../../modules/nf-core/lofreq/viterbi/main'
include { LOFREQ_INDELQUAL }    from '../../../modules/nf-core/lofreq/indelqual/main'
include { LOFREQ_CALLPARALLEL } from '../../../modules/nf-core/lofreq/callparallel/main'
include { SAMTOOLS_INDEX }      from '../../../modules/nf-core/samtools/index/main'


workflow BAM_CALL_VARIANT_ALL {

    take:
    tools           // String
    ch_bam          // channel: [ val(meta), [ bam ]   ]
    ch_ref          // channel: [ val(meta), [ fasta ] ]
    ch_ref_index    // channel: [ val(meta), [ fai ]   ]


    main:
    ch_iqbam    = Channel.empty()
    ch_bai      = Channel.empty()
    ch_vcf      = Channel.empty()
    ch_versions = Channel.empty()

    if (tools.split(',').contains('lofreq')) {
        // LOFREQ_VITERBI corrects mapping errors
        // LOFREQ_VITERBI nf-core module was implemented by @MarieLataretu and includes samtools sort. No need for an extra sorting step here.
        LOFREQ_VITERBI (
            ch_bam,
            ch_ref
        )
        ch_versions             = ch_versions.mix(LOFREQ_VITERBI.out.versions.first())

        // LOFREQ_INDELQUAL adds indel qualities to BAM files
        LOFREQ_INDELQUAL (
            LOFREQ_VITERBI.out.bam,
            ch_ref
        )
        ch_iqbam    = LOFREQ_INDELQUAL.out.bam
        ch_versions = ch_versions.mix(LOFREQ_INDELQUAL.out.versions.first())

        // LOFREQ_ALNQUAL adds alignment quality per base and indel
        // LOFREQ_ALNQUAL will not be taken over from FluPipe for now, as it is computed on the fly in lofreq call/call-parallel

        // SAMTOOLS_INDEX creates bam index
        SAMTOOLS_INDEX (
            ch_iqbam
        )
        ch_bai      = SAMTOOLS_INDEX.out.bai    // [ val(meta), path("*.bai") ]
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

        // LOFREQ_CALLPARALLEL does the actual variant calling
        // LOFREQ_CALLPARALLEL requires formatting of the input Channel
        ch_callbam = ch_iqbam
                        .join(ch_bai)
                        .map{ it -> [it[0], it[1], it[2], [] ] }
                        // [ val(meta), [bam], [bai], ""]

        LOFREQ_CALLPARALLEL (
            ch_callbam,
            ch_ref,
            ch_ref_index
        )
        ch_vcf      = LOFREQ_CALLPARALLEL.out.vcf
        ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())
    }

    emit:
    bam         = ch_iqbam      // channel: [ val(meta), [ bam ] ]  // Not the same as input bam! Here, the bam got normalized and annotated.
    bai         = ch_bai        // channel: [ val(meta), [ bai ] ]
    vcf         = ch_vcf        // channel: [ val(meta), [ vcf ] ]
    versions    = ch_versions   // channel: [ versions.yml ]
}

