process TOP1_REFERENCE {
    tag "$meta.id"

    /*
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/rkimf1/r-covpipe:89835bd--c37db5b' :
        'docker.io/rkimf1/r-covpipe:89835bd--c37db5b' }"
    */

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
    grep -v "#" ${spa} | \\
        head -n 1 | \\
        cut -f 1 \\
        > ${prefix}.top1id.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GNU grep: \$(grep --version | head -n 1 | cut -d ')' -f 2)
        GNU coreutils: \$(cut --version | head -n 1 | cut -d ')' -f 2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${spa}".split('\\.').take(2).join('.')

    """
    touch ${prefix}.top1id.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        GNU grep: \$(grep --version | head -n 1 | cut -d ')' -f 2)
        GNU coreutils: \$(cut --version | head -n 1 | cut -d ')' -f 2)
    END_VERSIONS
    """
}