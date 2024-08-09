process PREPARE_REFERENCE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/biopython%3A1.73':
        'biocontainers/biopython:v1.73dfsg-1-deb-py3_cv1' }"

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*preped.fasta")         , emit: preped_ref
    path  "versions.yml"                           , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    prep_reference.py --fasta ${fasta} --out ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prep_reference.py: \$(head -n 1 version.tmp)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_preped.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        prep_reference.py: '1.0.0'
    END_VERSIONS
    """
}
