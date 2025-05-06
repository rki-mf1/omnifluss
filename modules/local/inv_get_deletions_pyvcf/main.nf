process INV_GET_DELETIONS_PYVCF {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/pyvcf%3A0.6.8--py36_0':
        'biocontainers/pyvcf:v0.6.8git20170215.476169c-1-deb_cv1' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf")         , emit: del_vcf
    path  "versions.yml"                   , emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    get_deletions.py --vcf ${vcf} --out ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        get_deletions.py: \$(get_deletions.py --version | cut -d ' ' -f 2)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        get_deletions.py: \$(get_deletions.py --version | cut -d ' ' -f 2)
    END_VERSIONS
    """
}
