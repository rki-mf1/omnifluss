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
    outdir

    main:
    report                        = Channel.empty()
    versions                      = Channel.empty()
    read_statistics               = Channel.empty() //from here on, optional files
    kraken_classification         = Channel.empty()
    mapping_statistics            = Channel.empty()
    top5_references               = Channel.empty()
    N_content_and_Ambigiuos_calls = Channel.empty()

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
        outdir
    )
    report                        = INV_REPORT.out.report
    versions                      = INV_REPORT.out.versions
    //optional output
    read_statistics               = INV_REPORT.out.read_statistics
    kraken_classification         = INV_REPORT.out.kraken_classification
    mapping_statistics            = INV_REPORT.out.mapping_statistics
    top5_references               = INV_REPORT.out.top5_references
    N_content_and_Ambigiuos_calls = INV_REPORT.out.N_content_and_Ambigiuos_calls

    emit:
    report                        = report
    versions                      = versions
    read_statistics               = read_statistics
    kraken_classification         = kraken_classification
    mapping_statistics            = mapping_statistics
    top5_references               = top5_references
    N_content_and_Ambigiuos_calls = N_content_and_Ambigiuos_calls

}