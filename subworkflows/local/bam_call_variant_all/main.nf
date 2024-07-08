include { LOFREQ_VITERBI } from '../../../modules/nf-core/lofreq/viterbi/main'


workflow BAM_CALL_VARIANT_ALL {

    take:
    // TODO nf-core: edit input (take) channels
    ch_bam // channel: [ val(meta), [ bam ] ]
    ch_ref // channel: path(fasta)


    main:

    ch_iqbam    = Channel.empty()
    ch_tbam     = Channel.empty()
    ch_vcf      = Channel.empty()
    ch_versions = Channel.empty()

    LOFREQ_VITERBI (
        ch_bam, ch_ref
    )
    ch_realigned_sorted_bam = LOFREQ_VITERBI.out.bam
    ch_versions             = ch_versions.mix(LOFREQ_VITERBI.out.versions.first())



    emit:
    // TODO nf-core: edit emitted channels
    //iqbam    = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    //tbam     = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    //vcf      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

