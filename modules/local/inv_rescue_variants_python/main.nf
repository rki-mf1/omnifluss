process INV_RESCUE_VARIANTS_PYTHON {
    tag "$meta.id"

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.12' :
        'biocontainers/python:3.12' }"

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
    python $projectDir/bin/rescue_variants.py $vcf

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rescue_variants.py: \$(python $projectDir/bin/rescue_variants.py --version)
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch "${prefix}.special_case_variant_mask.bed"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        rescue_variants.py: \$(python $projectDir/bin/rescue_variants.py --version)
    END_VERSIONS
    """
}
