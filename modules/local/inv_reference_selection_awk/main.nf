process INV_GET_TOP1_REFERENCE_AWK {
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/gawk:5.3.1' :
        'biocontainers/gawk:5.3.1' }"

    input:
    tuple val(meta), path(spa)

    output:
    tuple val(meta), path("*.top1id.txt"),    emit: txt
    path "versions.yml",                            emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    //def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${spa}".split('\\.').take(2).join('.')

    """
    gawk -F'\t' '\$0 !~ /^#/ {print \$1; exit}' ${spa} > ${prefix}.top1id.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GNU Awk: \$(gawk --version | head -n 1 | cut -d ' ' -f 3 | cut -d ',' -f 1)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${spa}".split('\\.').take(2).join('.')

    """
    touch ${prefix}.top1id.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GNU Awk: \$(gawk --version | head -n 1 | cut -d ' ' -f 3 | cut -d ',' -f 1)
    END_VERSIONS
    """
}