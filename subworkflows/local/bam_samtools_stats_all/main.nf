include { SAMTOOLS_COVERAGE } from '../../../modules/nf-core/samtools/coverage/main'   //get_bamstats.smk
include { SAMTOOLS_FLAGSTAT } from '../../../modules/nf-core/samtools/flagstat/main'   //get_bamstats.smk

workflow BAM_SAMTOOLS_STATS_ALL {

    take:
    ch_mapping_var_calling      // channel: [ val(meta), bam ]
    ch_ref                      // channel: [ val(meta), fasta]
    ch_index                    // channel: [ val(meta), fai]

    main:
    ch_versions = Channel.empty()
    ch_multiqc_files  = Channel.empty()

    //getBamStats
    ch_bam_cpy = ch_mapping_var_calling.map{ meta, bam -> return [meta.id, meta, bam ] }
    ch_ref_cpy = ch_ref.map{ meta, ref -> return [meta.id, meta, ref ] }
    ch_index_cpy = ch_index.map { meta, idx -> return [meta.id, meta, idx ]}

    ch_samtools_coverage_input = ch_bam_cpy.join(ch_ref_cpy).join(ch_index_cpy)
        .multiMap{_sample_id, meta, bam, meta2, fasta, meta3, idx ->
            ch_bam: [meta, bam, []]
            ch_ref: [meta2, fasta]
            ch_index: [meta3, idx]
        }

    SAMTOOLS_COVERAGE(
        ch_samtools_coverage_input.ch_bam,
        ch_samtools_coverage_input.ch_ref,
        ch_samtools_coverage_input.ch_index
    )
    ch_cov_samtools = SAMTOOLS_COVERAGE.out.coverage
    ch_multiqc_files = ch_multiqc_files.mix(ch_cov_samtools.collect{it[1]})
    ch_versions = ch_versions.mix(SAMTOOLS_COVERAGE.out.versions)

    //getBamStats
    ch_mapping_flagstat_samtools = ch_mapping_var_calling
        | map {meta, bam -> [meta, bam, []]}

    SAMTOOLS_FLAGSTAT(
        ch_mapping_flagstat_samtools
    )
    ch_flagstat_samtools = SAMTOOLS_FLAGSTAT.out.flagstat
    ch_multiqc_files = ch_multiqc_files.mix(ch_flagstat_samtools.collect{it[1]})
    ch_versions = ch_versions.mix(SAMTOOLS_FLAGSTAT.out.versions)

    emit:
    samtools_cov         = ch_cov_samtools
    samtools_flagstat    = ch_flagstat_samtools
    multiqc_files        = ch_multiqc_files
    versions             = ch_versions
}