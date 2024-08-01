
include { LOFREQ_CALLPARALLEL as LOFREQ_CALLPARALLEL_SPEC_CASE }    from '../../../modules/nf-core/lofreq/callparallel/main'
include { LOFREQ_FILTER }                                           from '../../../modules/nf-core/lofreq/filter/main'
include { RESCUE_VARIANTS }                                         from '../../../modules/local/inv_variantCallingSpecialCase_pyvcf/main'


workflow BAM_SPECIAL_VARIANTS_CASE_ALL {

    take:
    ch_iqbam        // channel: [ val(meta), [ bam ]   ]
    ch_bai          // channel: [ val(meta), [ bai ]   ]
    ch_ref          // channel: [ val(meta), [ fasta ] ]
    ch_ref_index    // channel: [ val(meta), [ fai ]   ]


    main:
    ch_vcf      = Channel.empty()
    ch_bed      = Channel.empty()
    ch_versions = Channel.empty()

    // LOFREQ_CALLPARALLEL requires formatting of the input Channel
    ch_callbam = ch_iqbam
                    .join(ch_bai)
                    .map{ it -> [it[0], it[1], it[2], [] ] }
                    // [ val(meta), [bam], [bai], ""]

    // LOFREQ_CALLPARALLEL does the actual variant calling
    LOFREQ_CALLPARALLEL_SPEC_CASE (
        ch_callbam,
        ch_ref,
        ch_ref_index
    )
    ch_versions = ch_versions.mix(LOFREQ_CALLPARALLEL_SPEC_CASE.out.versions.first())

    // LOFREQ_FILTER is a non-default variant filter here; see conf
    LOFREQ_FILTER (
        LOFREQ_CALLPARALLEL_SPEC_CASE.out.vcf
    )
    ch_vcf      = LOFREQ_FILTER.out.vcf
    ch_versions = ch_versions.mix(LOFREQ_FILTER.out.versions.first())

    // RESCUE_VARIANTS is a custom python script that generates a bed file with HQ variant sites to be masked in the consensus
    RESCUE_VARIANTS (
        ch_vcf
    )
    ch_bed      = RESCUE_VARIANTS.out.bed
    ch_versions = ch_versions.mix(RESCUE_VARIANTS.out.versions.first())


    emit:
    vcf      = ch_vcf       // channel: [ val(meta), [ vcf ] ]
    bed      = ch_bed       // channel: [ val(meta), [ bed ] ]
    versions = ch_versions  // channel: [ versions.yml ]
}

