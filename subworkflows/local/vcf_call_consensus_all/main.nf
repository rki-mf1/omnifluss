include { BCFTOOLS_FILTER                            } from '../../../modules/nf-core/bcftools/filter/main'
include { INV_GET_DELETIONS_PYVCF                    } from '../../../modules/local/inv_get_deletions_pyvcf/main'
include { INV_SET_GT_BCFTOOLS                        } from '../../../modules/local/inv_set_gt_bcftools/main'
include { CREATE_MASK_CONSENSUS                      } from '../../../modules/local/inv_consensus_bedtools/main'
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

    if (tools.split(',').contains('bcftools')) {

        BCFTOOLS_FILTER(
            ch_vcf                      // channel: [ val(meta), vcf ]
        )
        .vcf
        | set {ch_filtered_vcf}

        ch_versions = ch_versions.mix(BCFTOOLS_FILTER.out.versions.first())

        // mask
        INV_GET_DELETIONS_PYVCF(
            ch_filtered_vcf             // channel: [ val(meta), vcf ]
        )
        .del_vcf
        | set {ch_del_adjusted_vcf}
        //note: no version save, because bcftools is used and it was incorporated prior

        // comprised createMaskConsensus & createMaskConsensus_special_variant_case in this module
        CREATE_MASK_CONSENSUS(
            val_consensus_mincov,       // integer
            ch_del_adjusted_vcf,        // channel: [ val(meta), vcf ]
            ch_bam,                     // channel: [ val(meta), bam ]
            ch_rescued_variants         // channel: [ val(meta), bed ]
        ).final_bed
        | set {ch_final_bed}

        ch_versions = ch_versions.mix(CREATE_MASK_CONSENSUS.out.versions.first())

        // vcf
        INV_SET_GT_BCFTOOLS(
            ch_filtered_vcf             // channel: [ val(meta), vcf ]
        ).vcf
        | set {ch_final_vcf}

        ch_versions = ch_versions.mix(INV_SET_GT_BCFTOOLS.out.versions.first())

        TABIX_TABIX(
            ch_final_vcf                // channel: [ val(meta), vcf ]
        ).tbi
        | set {ch_final_vcf_tbi}

        ch_versions = ch_versions.mix(TABIX_TABIX.out.versions.first())

        consensus_input = ch_final_vcf.join(ch_final_vcf_tbi, by:[0])
        consensus_input = consensus_input.combine( ch_ref.map{ it[1] } )
        consensus_input = consensus_input.join(ch_final_bed, by:[0])

        BCFTOOLS_CONSENSUS(
            consensus_input // channel: [ val(meta), vcf, tbi, fasta, bed ]
        )
        //note: no version save, because bcftools is used and it was incorporated prior
    }

    emit:
    consensus_calls     = BCFTOOLS_CONSENSUS.out.fasta
    versions            = ch_versions


}
