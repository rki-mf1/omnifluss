process ADJUST_GT_CONSENSUS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.20--h8b25389_0':
        'biocontainers/bcftools:1.20--h8b25389_0' }"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path("*.vcf.gz")      , emit: vcf
    path  "versions.yml"                   , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    bash add_fake_gt.sh  -i ${vcf} -g 1 -o ${prefix}.gt_adjust.vcf.gz.tmp
    bcftools index ${prefix}.gt_adjust.vcf.gz.tmp
    bcftools +setGT ${prefix}.gt_adjust.vcf.gz.tmp -- -t q -i 'GT="1" && INFO/AF < 0.9' -n 'c:0/1' | bcftools +setGT -o ${prefix}.gt_adjust.vcf.gz -- -t q -i 'GT="1" && INFO/AF >= 0.9' -n 'c:1/1' 
    bcftools index ${prefix}.gt_adjust.vcf.gz

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        add_fake_gt.sh: \$(head -n 1 version.tmp)
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.gt_adjust.vcf.gz
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        add_fake_gt.sh: \$(head -n 1 version.tmp)
        bcftools: \$(bcftools --version 2>&1 | head -n1 | sed 's/^.*bcftools //; s/ .*\$//')
    END_VERSIONS
    """
}
