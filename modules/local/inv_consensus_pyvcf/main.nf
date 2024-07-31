process ADJUST_DELETION_CONSENSUS {
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
    adjust_dels.py --name ${prefix} --vcf ${vcf}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        adjust_dels.py: \$(head -n 1 version.tmp)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.del_adjust.vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        adjust_dels.py: '1.0.0'
    END_VERSIONS
    """
}
