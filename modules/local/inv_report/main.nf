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
    path "qc_report.html"                       , emit: report
    path "versions.yml"                         , emit: versions
    path "read_statistics.csv"                  , optional: true, emit: read_statistics
    path "kraken_classification.csv"            , optional: true, emit: kraken_classification
    path "mapping_statistics.csv"               , optional: true, emit: mapping_statistics
    path "top5_references.csv"                  , optional: true, emit: top5_references
    path "N_content_and_Ambiguous_calls.csv"    , optional: true, emit: N_content_and_Ambiguous_calls

    script:
    """
    # create report
    cp -L ${script} report_copied.rmd

    # distinguishes between absolute and relative output path
    if [[ ${outdir} == /* ]]; then
        Rscript -e "rmarkdown::render('report_copied.rmd', params=list(proj_folder='${outdir}', min_cov=${params.consensus_mincov}, reference='${params.reference_selection}', information_json='${params.reporting_information}'), output_file='${outdir}/qc_report.html')"
        mv '${outdir}/qc_report.html' .
    else
        Rscript -e "rmarkdown::render('report_copied.rmd', params=list(proj_folder='${projectDir}/${outdir}', min_cov=${params.consensus_mincov}, reference='${params.reference_selection}', information_json='${params.reporting_information}'), output_file='${projectDir}/${outdir}/qc_report.html')"
        mv '${projectDir}/${outdir}/qc_report.html' .
    fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        report.rmd: \$(cat version.txt)
    END_VERSIONS
    """

    stub:
    """
    touch qc_report.html
    touch versions.yml
    """
}