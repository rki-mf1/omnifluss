include { INV_REPORT_RMARKDOWN } from '../../../modules/local/inv_report_rmarkdown/main'

workflow INV_REPORTING_ALL {
    take:
    reporting_script
    fastp_jsons
    kraken_reports
    mapping_references
    markduplicate_metrics
    bedtools_genomecov
    samtools_coverage
    samtools_flagstat
    consensus_calls
    empty_kraken2_reads
    empty_spa_files

    outdir
    main:
    report                         = Channel.empty()
    versions                       = Channel.empty()
    read_statistics                = Channel.empty() //from here on, optional files that are only produced if the necessary input is available
    kraken_classification          = Channel.empty()
    mapping_statistics             = Channel.empty()
    top5_references                = Channel.empty()
    N_content_and_Ambigiuous_calls = Channel.empty()

    INV_REPORT_RMARKDOWN(
        reporting_script,
        fastp_jsons,
        kraken_reports,
        mapping_references,
        markduplicate_metrics,
        bedtools_genomecov,
        samtools_coverage,
        samtools_flagstat,
        consensus_calls,
        empty_kraken2_reads,
        empty_spa_files,
        outdir
    )
    report                        = INV_REPORT_RMARKDOWN.out.report
    versions                      = INV_REPORT_RMARKDOWN.out.versions
    //optional output
    read_statistics               = INV_REPORT_RMARKDOWN.out.read_statistics
    kraken_classification         = INV_REPORT_RMARKDOWN.out.kraken_classification
    mapping_statistics            = INV_REPORT_RMARKDOWN.out.mapping_statistics
    top5_references               = INV_REPORT_RMARKDOWN.out.top5_references
    N_content_and_Ambiguous_calls = INV_REPORT_RMARKDOWN.out.N_content_and_Ambiguous_calls

    emit:
    report                        = report
    versions                      = versions
    read_statistics               = read_statistics
    kraken_classification         = kraken_classification
    mapping_statistics            = mapping_statistics
    top5_references               = top5_references
    N_content_and_Ambiguous_calls = N_content_and_Ambiguous_calls

}