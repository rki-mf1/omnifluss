process KMA {
    errorStrategy { task.exitStatus == 1 ? 'ignore' : 'terminate' } //allow errors (negative controls/bad samples)
    tag "$meta.id"
    label 'process_low'

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
    def prefix          = task.ext.prefix ?: "${meta.id}.${meta2.id}.kma"
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
    def prefix      = task.ext.prefix ?: "${meta.id}.${meta2.id}.kma"
    def create_mat  = mat_format ? "touch ${prefix}.mat.gz" : ''
    """
    touch ${prefix}.res \\
    touch ${prefix}.fsa \\
    touch ${prefix}.aln \\
    touch ${prefix}.frag.gz \\
    ${create_mat}

    echo -e \
        '#Template\tNum\tScore\tExpected\tTemplate_length\tQuery_Coverage\tTemplate_Coverage\tDepth\ttot_query_Coverage\ttot_template_Coverage\ttot_depth\tq_value\tp_value' > ${prefix}.spa
    echo -e \
        'ENA|PQ615339|PQ615339.1InfluenzaAvirus(A/California/173/2024(H5N1))segment7matrixprotein2(M2)andmatrixprotein1(M1)genescompletecds.\t4\t22907356\t9037744\t1974\t3.51\t46.61\t11604.54\t3.51\t46.61\t11604.54\t6021772.79\t1.0e-26' >> ${prefix}.spa


    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        kma: \$(echo \$(kma_index -v 2>&1) | sed 's/^KMA_index-\$//')
    END_VERSIONS
    """
}
