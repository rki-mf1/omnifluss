//
// Picard MarkDuplicates, index BAM file and run samtools stats, flagstat and idxstats
//

include { PICARD_MARKDUPLICATES } from '../../../modules/nf-core/picard/markduplicates/main'
include { SAMTOOLS_INDEX        } from '../../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS    } from '../bam_stats_samtools/main'

workflow BAM_MARKDUPLICATES_PICARD {

    take:
    ch_reads    // channel: [ val(meta), path(reads) ]
    ch_fasta    // channel: [ path(fasta) ]
    ch_fai      // channel: [ path(fai) ]

    main:

    ch_versions = Channel.empty()

    //sort channels to maintain order across different channels
    // ch_picard_markduplicates_input = ch_reads.join(ch_fasta).join(ch_fai)
    //     .multiMap{meta, reads, reference, fai_index ->
    //         ch_reads: [ meta, reads ]
    //         ch_ref: [ meta, reference ]
    //         ch_fai_index: [ meta, fai_index ]
    //     }

    ch_reads_cpy = ch_reads.map {meta, reads -> return [meta.id, meta, reads]} 
    ch_fasta_cpy = ch_fasta.map {meta, fasta -> return [meta.id, meta, fasta]}
    ch_fai_cpy = ch_fai.map {meta, fai -> return [meta.id, meta, fai]}

    ch_picard_markduplicates_input = ch_reads_cpy.join(ch_fasta_cpy).join(ch_fai_cpy)
        .multiMap{_sample_id, meta, reads, meta2, reference, meta3, fai_index ->
            ch_reads: [ meta, reads ]
            ch_ref: [ meta2, reference ]
            ch_fai_index: [ meta3, fai_index ]
        }

    PICARD_MARKDUPLICATES(
        ch_picard_markduplicates_input.ch_reads,
        ch_picard_markduplicates_input.ch_ref,
        ch_picard_markduplicates_input.ch_fai_index
    )
    ch_versions = ch_versions.mix(PICARD_MARKDUPLICATES.out.versions.first())

    ch_markdup = PICARD_MARKDUPLICATES.out.bam.mix(PICARD_MARKDUPLICATES.out.cram)

    SAMTOOLS_INDEX ( ch_markdup )
    ch_versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions.first())

    ch_reads_index = ch_markdup
        .join(SAMTOOLS_INDEX.out.bai,  by: [0], remainder: true)
        .join(SAMTOOLS_INDEX.out.crai, by: [0], remainder: true)
        .join(SAMTOOLS_INDEX.out.csi,  by: [0], remainder: true)
        .map{meta, reads, bai, crai, csi ->
            if (bai) [ meta, reads, bai ]
            else if (crai) [ meta, reads, crai ]
            else [ meta, reads, csi ]
        }

    BAM_STATS_SAMTOOLS ( ch_reads_index, ch_fasta )
    ch_versions = ch_versions.mix(BAM_STATS_SAMTOOLS.out.versions)

    emit:
    bam      = PICARD_MARKDUPLICATES.out.bam     // channel: [ val(meta), path(bam) ]
    cram     = PICARD_MARKDUPLICATES.out.cram    // channel: [ val(meta), path(cram) ]
    metrics  = PICARD_MARKDUPLICATES.out.metrics // channel: [ val(meta), path(metrics) ]
    bai      = SAMTOOLS_INDEX.out.bai            // channel: [ val(meta), path(bai) ]
    crai     = SAMTOOLS_INDEX.out.crai           // channel: [ val(meta), path(crai) ]
    csi      = SAMTOOLS_INDEX.out.csi            // channel: [ val(meta), path(csi) ]

    stats    = BAM_STATS_SAMTOOLS.out.stats      // channel: [ val(meta), path(stats) ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat   // channel: [ val(meta), path(flagstat) ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats   // channel: [ val(meta), path(idxstats) ]

    versions = ch_versions                       // channel: [ versions.yml ]
}
