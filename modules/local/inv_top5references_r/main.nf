
process TOP5_REFERENCES {
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'docker.io/rkimf1/r-covpipe:89835bd--c37db5b' :
        'docker.io/rkimf1/r-covpipe:89835bd--c37db5b' }"

    input:
    tuple val(meta), path(paf)

    output:
    tuple val(meta), path("*_best_refs.txt"),   emit: txt
    path "versions.yml"                     ,   emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    Rscript \\
        ${projectDir}/bin/minimap_stats.r \\
        $paf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap_stats.r: \$(${projectDir}/bin/minimap_stats.r --version)
    END_VERSIONS
    """

    stub:
    """
    touch top5_best_refs.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        minimap_stats.r: \$(${projectDir}/bin/minimap_stats.r --version)
    END_VERSIONS
    """
}
