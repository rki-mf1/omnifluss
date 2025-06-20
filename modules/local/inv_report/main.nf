process INV_REPORT {
    tag "reporting"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "oras://community.wave.seqera.io/library/bioconductor-shortread_r-data.table_r-dplyr_r-formattable_pruned:91e8b683750411aa"

    input:
    path(script)
    path(fastp_jsons)
    path(kraken_reports)
    path(mapping_references)
    path(markduplicate_metrics)
    path(bedtools_genomecov)
    path(samtools_coverage)
    path(samtools_flagstat)
    path(consensus_calls)
    val(outdir)

    output:
    path("qc_report.html")

    script:
    """
    # create report
    cp -L ${script} report_copied.rmd

    # distinguishes between absolute and relative output path
    if [[ ${outdir} == /* ]]; then
        Rscript -e "rmarkdown::render('report_copied.rmd', params=list(proj_folder='${outdir}', list_folder='${outdir}/reporting_files', min_cov=${params.consensus_mincov}, reference='${params.reference_selection}', information_json='${params.reporting_information}'), output_file='${outdir}/qc_report.html')"
        mv '${outdir}/qc_report.html' .
    else
        Rscript -e "rmarkdown::render('report_copied.rmd', params=list(proj_folder='${projectDir}/${outdir}', list_folder='${projectDir}/${outdir}/reporting_files', min_cov=${params.consensus_mincov}, reference='${params.reference_selection}', information_json='${params.reporting_information}'), output_file='${projectDir}/${outdir}/qc_report.html')"
        mv '${projectDir}/${outdir}/qc_report.html' .
    fi
    """

    stub:
    """
    touch qc_report.html
    """
}