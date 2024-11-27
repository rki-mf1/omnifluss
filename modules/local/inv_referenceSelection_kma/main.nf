process KMA {
    tag "$meta.id"
    label 'process_single'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kma:1.4.15--he4a0461_0' :
        'biocontainers/kma:1.4.15--he4a0461_0' }"

    input:
    tuple val(meta) , path(reads)
    tuple val(meta2), path(index)
    val interleaved
    val mat_format

    output:
    tuple val(meta), path("*.res"),     emit: res
    tuple val(meta), path("*.fsa"),     emit: fsa
    tuple val(meta), path("*.aln"),     emit: aln
    tuple val(meta), path("*.frag.gz"), emit: frag
    tuple val(meta), path("*.mat.gz"),  optional: true, emit: mat
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args        = task.ext.args ?: ''
    def prefix      = task.ext.prefix ?: "${meta.id}.kma"
    def input_style = interleaved ? "-int ${reads}" : "-ipe ${reads}"
    def create_mat  = mat_format ? "-matrix" : ''
    """
    kma \\
        ${input_style} \\
        -o ${prefix} \\
        -t_db ${index} \\
        ${create_mat} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kma: \$(echo \$(kma_index -v 2>&1) | sed 's/^KMA_index-\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}.kma"
    def create_mat  = mat_format ? "touch ${prefix}.mat.gz" : ''
    """
    touch ${prefix}.res \\
    touch ${prefix}.fsa \\
    touch ${prefix}.aln \\
    touch ${prefix}.frag.gz \\
    ${create_mat}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kma: \$(echo \$(kma_index -v 2>&1) | sed 's/^KMA_index-\$//')
    END_VERSIONS
    """
}
