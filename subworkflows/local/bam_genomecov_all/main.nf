include { BEDTOOLS_GENOMECOV } from '../../../modules/nf-core/bedtools/genomecov/main' //get_read_cov.smk

workflow BAM_GENOMECOV_ALL {

    take:
    ch_mapping                  // channel: [ val(meta), bam]
    sizes                       // File
    extension                   // String
    sort                        // Bool

    main:
    ch_versions = Channel.empty()

    //get_read_cov.smk
    ch_mapping_bedtools = ch_mapping 
        | map {meta, bam -> [meta, bam, 1]} //setting scale factor to 1 disables it.

    BEDTOOLS_GENOMECOV(
        ch_mapping_bedtools, 
        sizes,      
        extension,
        sort
    )
    ch_cov_bedtools = BEDTOOLS_GENOMECOV.out.genomecov
    ch_versions = ch_versions.mix(BEDTOOLS_GENOMECOV.out.versions)

    emit:
    bedtools_cov         = ch_cov_bedtools
    versions             = ch_versions
    
}