include { BWA_INDEX              } from '../../../modules/nf-core/bwa/index/main'
include { FASTQ_ALIGN_BWA        } from '../../nf-core/fastq_align_bwa/main'

workflow FASTP_MAP_ALL {
    take:
    tools
    ch_reads
    reference

    main:
    ch_index = Channel.empty()
    ch_bam_orig = Channel.empty()
    ch_bam = Channel.empty()
    ch_csi = Channel.empty()
    ch_stats = Channel.empty()
    ch_flagstat = Channel.empty()
    ch_idxstats = Channel.empty()
    ch_versions = Channel.empty()

    if (tools.split(',').contains('bwa')) {

        BWA_INDEX(
            reference
        )
        ch_index = BWA_INDEX.out.index
        ch_versions = ch_versions.mix(BWA_INDEX.out.versions)

        FASTQ_ALIGN_BWA(
            ch_reads,
            ch_index,
            true,
            reference
        )
        ch_bam_orig = FASTQ_ALIGN_BWA.out.bam_orig
        ch_bam = FASTQ_ALIGN_BWA.out.bam
        ch_csi = FASTQ_ALIGN_BWA.out.csi
        ch_stats = FASTQ_ALIGN_BWA.out.stats
        ch_flagstat = FASTQ_ALIGN_BWA.out.flagstat
        ch_idxstats = FASTQ_ALIGN_BWA.out.idxstats
        ch_versions = ch_versions.mix(FASTQ_ALIGN_BWA.out.versions.first())

    }
    emit:
    ch_mapping        = ch_bam
    versions          = ch_versions

}

