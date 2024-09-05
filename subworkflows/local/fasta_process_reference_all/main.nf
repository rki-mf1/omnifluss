include { INV_PREPARE_REFERENCE } from '../../../modules/local/inv_process_reference_biopython/main'
include { SAMTOOLS_FAIDX    } from '../../../modules/nf-core/samtools/faidx/main'
include { BWA_INDEX         } from '../../../modules/nf-core/bwa/index/main'


workflow FASTA_PROCESS_REFERENCE_ALL {
    take:
    tools                    // string
    aligner                  // string
    ref                      // channel: [ val(meta), fasta ]

    main:
    ch_versions = Channel.empty()
    ch_preped_ref = Channel.empty()
    ch_fai_index = Channel.empty()
    ch_bwa_index = Channel.empty()

    if (tools.split(',').contains('inv_prep_ref')) {
        INV_PREPARE_REFERENCE(
            ref
        ).preped_ref
        | set {ch_preped_ref}

        ch_versions = ch_versions.mix(INV_PREPARE_REFERENCE.out.versions.first())
    }

    if (tools.split(',').contains('samtools_faidx')) {
        SAMTOOLS_FAIDX(
            ch_preped_ref,
            [[],[]]
        ).fai
        | set {ch_fai_index}

        ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions.first())
    }

    if (aligner.split(',').contains('bwa')) {
        BWA_INDEX(
            ch_preped_ref
        ).index
        | set {ch_bwa_index}

        ch_versions = ch_versions.mix(BWA_INDEX.out.versions)
    }

    emit:
    preped_ref           = ch_preped_ref
    fai_index            = ch_fai_index
    bwa_index            = ch_bwa_index

    versions             = ch_versions

}

