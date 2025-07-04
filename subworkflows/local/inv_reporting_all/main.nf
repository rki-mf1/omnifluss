include { INV_REPORT } from '../../../modules/local/inv_report/main'

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

    main:
    report   = Channel.empty()
    versions = Channel.empty()

    INV_REPORT(
        reporting_script,
        fastp_jsons,
        kraken_reports,
        mapping_references,
        markduplicate_metrics,
        bedtools_genomecov,
        samtools_coverage,
        samtools_flagstat,
        consensus_calls,
        params.outdir
    )
    report = INV_REPORT.out.report
    versions = INV_REPORT.out.versions

    emit:
    report = report
    versions = versions

}