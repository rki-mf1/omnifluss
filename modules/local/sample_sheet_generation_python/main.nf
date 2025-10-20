process SAMPLE_SHEET_GENERATION_PYTHON {

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/python:3.12'
        : 'biocontainers/python:3.12'}"

    input:
    val input
    val outdir
    val projectDir

    output:
    path "omnifluss_sample_sheet.csv"      , emit: sample_sheet
    path "versions.yml"                    , emit: versions

    script:
    """
    generate_sample_sheet.py --input "$input" --outdir "$outdir" --project_dir "$projectDir"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        generate_sample_sheet.py: \$(generate_sample_sheet.py --version | cut -d ' ' -f 2)
    END_VERSIONS
    """

    stub:
    """
    touch omnifluss_sample_sheet.csv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        generate_sample_sheet.py: \$(generate_sample_sheet.py --version | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
