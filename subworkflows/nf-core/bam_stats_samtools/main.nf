//
// Run SAMtools stats, flagstat and idxstats
//

include { SAMTOOLS_STATS    } from '../../../modules/nf-core/samtools/stats/main'
include { SAMTOOLS_IDXSTATS } from '../../../modules/nf-core/samtools/idxstats/main'
include { SAMTOOLS_FLAGSTAT } from '../../../modules/nf-core/samtools/flagstat/main'

workflow BAM_STATS_SAMTOOLS {
    take:
    ch_bam_bai // channel: [ val(meta), path(bam), path(bai) ]
    ch_fasta   // channel: [ val(meta), path(fasta) ]

    main:
    ch_versions = Channel.empty()

    //sort channels to maintain order across different channels
    ch_bam_bai_cpy = ch_bam_bai.map {meta, bam, bai -> return [meta.id, meta, bam, bai]} 
    ch_fasta_cpy = ch_fasta.map {meta, fasta -> return [meta.id, meta, fasta]} 

    ch_samtools_stats_input = ch_bam_bai_cpy.join(ch_fasta_cpy)
        .multiMap{_sample_id, meta, bam, bai, meta2, reference ->
            ch_bam_bai: [ meta, bam, bai ]
            ch_ref: [ meta2, reference ]
        } 

    SAMTOOLS_STATS ( ch_samtools_stats_input.ch_bam_bai, ch_samtools_stats_input.ch_ref )
    ch_versions = ch_versions.mix(SAMTOOLS_STATS.out.versions)

    SAMTOOLS_FLAGSTAT ( ch_bam_bai )
    ch_versions = ch_versions.mix(SAMTOOLS_FLAGSTAT.out.versions)

    SAMTOOLS_IDXSTATS ( ch_bam_bai )
    ch_versions = ch_versions.mix(SAMTOOLS_IDXSTATS.out.versions)

    emit:
    stats    = SAMTOOLS_STATS.out.stats       // channel: [ val(meta), path(stats) ]
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat // channel: [ val(meta), path(flagstat) ]
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats // channel: [ val(meta), path(idxstats) ]

    versions = ch_versions                    // channel: [ path(versions.yml) ]
}
