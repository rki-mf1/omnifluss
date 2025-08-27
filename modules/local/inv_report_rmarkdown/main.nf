process INV_REPORT_RMARKDOWN {
    cache false
    tag "reporting"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
            'oras://community.wave.seqera.io/library/bioconductor-shortread_r-data.table_r-dplyr_r-formattable_pruned:91e8b683750411aa' :
            'community.wave.seqera.io/library/bioconductor-shortread_pandoc_r-base_r-data.table_pruned:8772a4bbf7f04989' }"

    input:
    path(script)
    path(sample_sheet)
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
    cp -L ${script} inv_report_copied.rmd

    # distinguish between absolute and relative path
    if [[ ${outdir} == /* ]]; then
        full_outdir="${outdir}"
    else
        full_outdir="${projectDir}/${outdir}"
    fi

    # move invalid files to sub directory
    mkdir invalid_files
    if [[ "${empty_kraken2_reads}" != "" ]]; then
        mv ${empty_kraken2_reads} invalid_files
    fi
    if [[ "${empty_spa_files}" != "" ]]; then
        mv ${empty_spa_files} invalid_files
    fi

    Rscript -e "rmarkdown::render('inv_report_copied.rmd', params=list(proj_folder='\${full_outdir}', min_cov=${params.consensus_mincov}, reference='${params.reference_selection}', information_json='${params.reporting_information}', sample_sheet='${sample_sheet}'), output_file='\${full_outdir}/qc_report.html')"
    mv \${full_outdir}/qc_report.html .

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        inv_report.rmd: \$(grep 'version:' inv_report_copied.rmd | cut -d ':' -f2)
    END_VERSIONS
    """

    stub:
    """
    cp -L ${script} inv_report_copied.rmd
    
    touch qc_report.html
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        inv_report.rmd: \$(grep 'version:' inv_report_copied.rmd | cut -d ':' -f2)
    END_VERSIONS

    #optional files
    touch read_statistics.csv
    touch kraken_classification.csv
    touch mapping_statistics.csv
    touch top5_references.csv
    touch N_content_and_Ambiguous_calls.csv
    """
}