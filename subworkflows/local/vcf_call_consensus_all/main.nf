include { BCFTOOLS_FILTER                            } from '../../../modules/nf-core/bcftools/filter/main'
include { INV_GET_DELETIONS_PYVCF                    } from '../../../modules/local/inv_get_deletions_pyvcf/main'
include { INV_CREATE_CONSENSUS_MASK_BEDTOOLS         } from '../../../modules/local/inv_create_consensus_mask_bedtools/main'
include { INV_SET_GT_BCFTOOLS                        } from '../../../modules/local/inv_set_gt_bcftools/main'
include { TABIX_TABIX                                } from '../../../modules/nf-core/tabix/tabix/main'
include { BCFTOOLS_CONSENSUS                         } from '../../../modules/nf-core/bcftools/consensus/main'

workflow VCF_CALL_CONSENSUS_ALL {
    take:
    tools                       // string
    val_consensus_mincov        // integer
    ch_ref                      // channel: [ val(meta), fasta ]
    ch_vcf                      // channel: [ val(meta), vcf   ]
    ch_bam                      // channel: [ val(meta), bam   ]
    ch_rescued_variants         // channel: [ val(meta), bed   ]

    main:
    ch_versions                 = Channel.empty()
    ch_filtered_vcf             = Channel.empty()
    ch_del_adjusted_vcf         = Channel.empty()
    ch_final_bed                = Channel.empty()
    ch_final_vcf                = Channel.empty()

    if (tools.split(',').contains('bcftools')) {

        BCFTOOLS_FILTER(
            ch_vcf                      // channel: [ val(meta), vcf ]
        )
        ch_filtered_vcf = BCFTOOLS_FILTER.out.vcf
        ch_versions = ch_versions.mix(BCFTOOLS_FILTER.out.versions.first())

        if (workflow.profile.contains("INV")) {
        // mask
        INV_GET_DELETIONS_PYVCF(
            ch_filtered_vcf             // channel: [ val(meta), vcf ]
        )
        ch_del_adjusted_vcf = INV_GET_DELETIONS_PYVCF.out.del_vcf
        ch_versions = ch_versions.mix(INV_GET_DELETIONS_PYVCF.out.versions.first())


        // prepare input channel
        ch_del_adjusted_vcf_cpy     = ch_del_adjusted_vcf.map{ meta, vcf -> return [meta.id, meta, vcf ] }
        ch_bam_cpy                  = ch_bam.map{ meta, bam -> return [meta.id, meta, bam] }
        ch_rescued_variants_cpy     = ch_rescued_variants.map{ meta, bed -> return [meta.id, meta, bed] }

        ch_create_consensus_mask_bedtools_input = ch_del_adjusted_vcf_cpy.join(ch_bam_cpy).join(ch_rescued_variants_cpy)
            .multiMap{_sample_id, meta, vcf, meta2, bam, meta3, bed ->
                ch_del_adjusted_vcf: [meta, vcf]
                ch_bam: [meta2, bam]
                ch_rescued_variants: [meta3, bed]
            }

        // comprised createMaskConsensus & createMaskConsensus_special_variant_case in this module
        INV_CREATE_CONSENSUS_MASK_BEDTOOLS(
            val_consensus_mincov,                                               // integer
            ch_create_consensus_mask_bedtools_input.ch_del_adjusted_vcf,        // channel: [ val(meta), vcf ]
            ch_create_consensus_mask_bedtools_input.ch_bam,                     // channel: [ val(meta), bam ]
            ch_create_consensus_mask_bedtools_input.ch_rescued_variants         // channel: [ val(meta), bed ]
        )
        ch_final_bed = INV_CREATE_CONSENSUS_MASK_BEDTOOLS.out.final_bed
        ch_versions = ch_versions.mix(INV_CREATE_CONSENSUS_MASK_BEDTOOLS.out.versions.first())

        // vcf
        INV_SET_GT_BCFTOOLS(
            ch_filtered_vcf             // channel: [ val(meta), vcf ]
        )
        ch_final_vcf = INV_SET_GT_BCFTOOLS.out.vcf
        ch_versions = ch_versions.mix(INV_SET_GT_BCFTOOLS.out.versions.first())
        }
        
        TABIX_TABIX(
            ch_final_vcf                // channel: [ val(meta), vcf ]
        )
        ch_final_vcf_tbi = TABIX_TABIX.out.tbi
        ch_versions = ch_versions.mix(TABIX_TABIX.out.versions.first())


        // prepare input channel
        ch_final_vcf_cpy       = ch_final_vcf.map{ meta, vcf -> return [meta.id, meta, vcf ] }
        ch_final_vcf_tbi_cpy   = ch_final_vcf_tbi.map{ meta, tbi -> return [meta.id, meta, tbi ]}
        ch_ref_cpy             = ch_ref.map{ meta, fasta -> return [meta.id, meta, fasta] }
        ch_final_bed_cpy       = ch_final_bed.map{ meta, bed -> return [meta.id, meta, bed] }

        ch_bcftools_consensus_input = ch_final_vcf_cpy.join(ch_final_vcf_tbi_cpy).join(ch_ref_cpy).join(ch_final_bed_cpy)
            .map{_sample_id, meta, vcf, _meta2, tbi, _meta3, fasta, _meta4, bed -> return [ meta , vcf, tbi, fasta, bed]}

        ch_bcftools_consensus_input.view()
        
        BCFTOOLS_CONSENSUS(
            ch_bcftools_consensus_input // channel: [ val(meta), vcf, tbi, fasta, bed ]
        )
        //note: no version save, because bcftools is used and it was incorporated prior
    }

    emit:
    consensus_calls     = BCFTOOLS_CONSENSUS.out.fasta
    versions            = ch_versions


}
