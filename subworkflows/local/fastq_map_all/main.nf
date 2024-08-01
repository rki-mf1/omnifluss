
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
    ch_bam             = Channel.empty()
    ch_bam_sorted      = Channel.empty()
    ch_csi             = Channel.empty()
    ch_stats           = Channel.empty()
    ch_flagstat        = Channel.empty()
    ch_idxstats        = Channel.empty()
    ch_versions        = Channel.empty()

    if (tools.split(',').contains('bwa')) {

        FASTQ_ALIGN_BWA(
            ch_reads,       // channel: [ val(meta), fastq ]
            ch_bwa_index,   // channel: [ val(meta), index ]
            true,
            ch_ref          // channel: [ val(meta), fasta ]
        )
        ch_bam          = FASTQ_ALIGN_BWA.out.bam_orig
        ch_bam_sorted   = FASTQ_ALIGN_BWA.out.bam
        ch_csi          = FASTQ_ALIGN_BWA.out.csi
        ch_stats        = FASTQ_ALIGN_BWA.out.stats
        ch_flagstat     = FASTQ_ALIGN_BWA.out.flagstat
        ch_idxstats     = FASTQ_ALIGN_BWA.out.idxstats
        ch_versions     = ch_versions.mix(FASTQ_ALIGN_BWA.out.versions.first())
    }


    PICARD_MARKDUPLICATES(
        ch_bam_sorted,         // channel: [ val(meta), bam ]
        ch_ref,
        [[], []]               // channel: [ val(meta), index ]
    )
    ch_deduped_bam  = PICARD_MARKDUPLICATES.out.bam
    ch_versions     = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions.first())


    emit:
    bam           = ch_bam_sorted
    deduped_bam   = ch_deduped_bam
    versions      = ch_versions

}

