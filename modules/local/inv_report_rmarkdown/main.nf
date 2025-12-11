process INV_REPORT_RMARKDOWN {
    cache false
    tag "reporting"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'oras://community.wave.seqera.io/library/bioconductor-shortread_r-data.table_r-dplyr_r-formattable_pruned:91e8b683750411aa' :
            'community.wave.seqera.io/library/bioconductor-shortread_pandoc_r-base_r-data.table_pruned:8772a4bbf7f04989' }"

    input:
    val(num_samples)
    val(consensus_mincov)
    val(reference_selection)
    path(reporting_information)
    path(fastp_jsons)
    path(kraken_reports)
    path(mapping_references)
    path(markduplicate_metrics)
    path(bedtools_genomecov)
    path(samtools_coverage)
    path(samtools_flagstat)
    path(consensus_calls)
    path(empty_kraken2_reads)
    path(empty_spa_files)

    output:
    path "qc_report.html"                                      , emit: report
    path "qc_report_data"                                      , optional: true, emit: data
    path "qc_report_data/read_statistics.csv"                  , optional: true, emit: read_statistics
    path "qc_report_data/kraken_classification.csv"            , optional: true, emit: kraken_classification
    path "qc_report_data/mapping_statistics.csv"               , optional: true, emit: mapping_statistics
    path "qc_report_data/top5_references.csv"                  , optional: true, emit: top5_references
    path "qc_report_data/N_content_and_Ambiguous_calls.csv"    , optional: true, emit: N_content_and_Ambiguous_calls
    path "versions.yml"                                        , emit: versions

    script:
    def reporting_information_file = reporting_information ? reporting_information : 'none'
    """
    # create report
    cp -L ${projectDir}/bin/inv_report.rmd inv_report_copied.rmd

    # move invalid files to sub directory
    mkdir invalid_files
    if [[ "${empty_kraken2_reads}" != "" ]]; then
        mv ${empty_kraken2_reads} invalid_files
    fi
    if [[ "${empty_spa_files}" != "" ]]; then
        mv ${empty_spa_files} invalid_files
    fi

    Rscript -e "rmarkdown::render('inv_report_copied.rmd', params=list(min_cov=${consensus_mincov}, reference='${reference_selection}', information_json='${reporting_information_file}', num_samples='${num_samples}'), output_file='qc_report.html')"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        inv_report.rmd: \$(grep 'version:' inv_report_copied.rmd | cut -d ':' -f2)
    END_VERSIONS
    """

    stub:
    """
    cp -L ${projectDir}/bin/inv_report.rmd inv_report_copied.rmd

    touch qc_report.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        inv_report.rmd: \$(grep 'version:' inv_report_copied.rmd | cut -d ':' -f2)
    END_VERSIONS

    # optional files
    mkdir qc_report_data
    touch qc_report_data/read_statistics.csv
    touch qc_report_data/kraken_classification.csv
    touch qc_report_data/mapping_statistics.csv
    touch qc_report_data/top5_references.csv
    touch qc_report_data/N_content_and_Ambiguous_calls.csv
    """
}
