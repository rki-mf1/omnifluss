process KMA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kma:1.4.15--he4a0461_0' :
        'biocontainers/kma:1.4.15--he4a0461_0' }"

    input:
    tuple val(meta) , path(reads), path(index)
    val interleaved
    val mat_format

    output:
    tuple val(meta), path("*.res"),     optional: true, emit: res
    tuple val(meta), path("*.fsa"),     optional: true, emit: fsa
    tuple val(meta), path("*.aln"),     optional: true, emit: aln
    tuple val(meta), path("*.frag.gz"), optional: true, emit: frag
    tuple val(meta), path("*.mat.gz"),  optional: true, emit: mat   // if mat_format == true
    tuple val(meta), path("*.spa"),     optional: true, emit: spa   // if ext.args = '-Sparse' (only output in this case)
    path "versions.yml"               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args            = task.ext.args ?: ''
    def prefix          = task.ext.prefix ?: "${meta.id}.kma"
    def input_style     = interleaved ? "-int ${reads}" : "-ipe ${reads}"
    def create_mat      = mat_format ? "-matrix" : ''
    """
    INDEX=`find -L ./ -name "*.name" | sed 's/\\.name\$//'`

    kma \\
        ${input_style} \\
        -o ${prefix} \\
        -t_db \$INDEX \\
        ${create_mat} \\
        $args

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kma: \$(echo \$(kma_index -v 2>&1) | sed 's/^KMA_index-\$//')
    END_VERSIONS
    """

    stub:
    def prefix      = task.ext.prefix ?: "${meta.id}.kma"
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
