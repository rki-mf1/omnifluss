
include { FASTQ_ALIGN_BWA        } from '../../nf-core/fastq_align_bwa/main'
include { SAMTOOLS_FAIDX         } from '../../../modules/nf-core/samtools/faidx/main'
include { PICARD_MARKDUPLICATES  } from '../../../modules/nf-core/picard/markduplicates/main'

workflow FASTQ_MAP_ALL {
    take:
    tools           // string
    ch_reads        // channel: [ val(meta), fastq ]
    ch_ref          // channel: [ val(meta), fasta ]
    ch_bwa_index    // channel: [ val(meta), index ]

    main:
    ch_bam      = Channel.empty()
    ch_versions = Channel.empty()

    if (tools.split(',').contains('bwa')) {

        FASTQ_ALIGN_BWA(
            ch_reads,       // channel: [ val(meta), fastq ]
            ch_bwa_index,   // channel: [ val(meta), index ]
            true,
            ch_ref          // channel: [ val(meta), fasta ]
        )
        ch_bam          = FASTQ_ALIGN_BWA.out.bam
        ch_versions     = ch_versions.mix(FASTQ_ALIGN_BWA.out.versions.first())
    }

    if (tools.split(',').contains('picard_remove_duplicates')) {
        PICARD_MARKDUPLICATES(
            ch_bam,         // channel: [ val(meta), bam ]
            [[], []],
            [[], []]        // channel: [ val(meta), index ]
        )
        ch_bam      = PICARD_MARKDUPLICATES.out.bam
        ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions.first())
    }

    emit:
    bam           = ch_bam
    versions      = ch_versions

}

