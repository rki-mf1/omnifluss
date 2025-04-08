
include { FASTQ_ALIGN_BWA        } from '../../nf-core/fastq_align_bwa/main'
include { SAMTOOLS_FAIDX         } from '../../../modules/nf-core/samtools/faidx/main'
include { BAM_MARKDUPLICATES_PICARD } from '../../nf-core/bam_markduplicates_picard/main'

workflow FASTQ_MAP_ALL {
    take:
    tools           // string
    ch_reads        // channel: [ val(meta), fastq ]
    ch_bwa_index    // channel: [ val(meta), index ]
    ch_ref          // channel: [ val(meta), fasta ]
    ch_fai_index    // channel: [ val(meta), index ]

    main:
    ch_bam      = Channel.empty()
    ch_bai      = Channel.empty()
    ch_versions = Channel.empty()

    if (tools.split(',').contains('bwa')) {

        FASTQ_ALIGN_BWA(
            ch_reads,       // channel: [ val(meta), fastq ]
            ch_bwa_index,   // channel: [ val(meta), index ]
            true,
            ch_ref          // channel: [ val(meta), fasta ]
        )
        ch_bam      = FASTQ_ALIGN_BWA.out.bam
        ch_bai      = FASTQ_ALIGN_BWA.out.bai
        ch_versions = ch_versions.mix(FASTQ_ALIGN_BWA.out.versions.first())
    }


    if (tools.split(',').contains('picard_remove_duplicates')) {

        BAM_MARKDUPLICATES_PICARD(
            ch_bam,          // channel: [ val(meta), bam ]
            ch_ref,          // channel: [ val(meta), ref ]
            ch_fai_index     // channel: [ val(meta), fai ]
        )
        ch_bam      = BAM_MARKDUPLICATES_PICARD.out.bam
        ch_bai      = BAM_MARKDUPLICATES_PICARD.out.bai
        ch_versions = ch_versions.mix(BAM_MARKDUPLICATES_PICARD.out.versions.first())
    }

    emit:
    bam           = ch_bam
    bai           = ch_bai
    versions      = ch_versions

}

