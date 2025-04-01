process INV_CREATE_CONSENSUS_MASK_BEDTOOLS {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bedtools:2.31.1--hf5e1c6e_0' :
        'biocontainers/bedtools:2.31.1--hf5e1c6e_0' }"

    input:
    val consensus_mincov
    tuple val(meta), path(vcf)
    tuple val(meta2), path(bam)
    tuple val(meta3), path(special_var)

    output:
    tuple val(meta), path("*.lowcov.bed")         , emit: lowcov_bed
    tuple val(meta), path("*.final.bed")          , emit: final_bed
    path  "versions.yml"                          , emit: versions

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    bedtools genomecov -bga -ibam ${bam} | awk '\$4 < ${consensus_mincov}' | bedtools merge > ${prefix}.tmp_bed
    bedtools subtract -a ${prefix}.tmp_bed -b ${vcf} > ${prefix}.lowcov.bed
    cat ${prefix}.lowcov.bed ${special_var} > ${prefix}.final.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.lowcov.bed
    touch ${prefix}.final.bed

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        bedtools: \$(bedtools --version | sed -e "s/bedtools v//g")
    END_VERSIONS
    """
}
