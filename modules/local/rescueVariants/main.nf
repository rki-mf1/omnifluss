process RESCUE_VARIANTS {
    tag "$meta.id"

    input:
    tuple val(meta), path(vcf)

    output:
    tuple val(meta), path('*.special_case_variant_mask.bed'), emit: bed
    path "versions.yml"                                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    python $projectDir/bin/rescue_HQ_variants.py $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """
    
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.special_case_variant_mask.bed"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        fastp: \$(fastp --version 2>&1 | sed -e "s/fastp //g")
    END_VERSIONS
    """
}
