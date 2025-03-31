include { INV_REPORT } from '../../../modules/local/inv_report/main'

workflow INV_REPORTING_ALL {
    take:
    reporting_script
    fastp_jsons
    kraken_reports
    markduplicate_metrics
    bedtools_genomecov
    samtools_coverage
    samtools_flagstat
    consensus_calls

    main:
    INV_REPORT(
        reporting_script,
        fastp_jsons,
        kraken_reports,
        markduplicate_metrics,
        bedtools_genomecov,
        samtools_coverage,
        samtools_flagstat,
        consensus_calls,
        params.outdir
    )
}