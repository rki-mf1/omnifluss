include { PREPARE_REFERENCE } from '../../../modules/local/inv_consensus_biopython/main'
include { SAMTOOLS_FAIDX    } from '../../../modules/nf-core/samtools/faidx/main'
include { BWA_INDEX         } from '../../../modules/nf-core/bwa/index/main'


workflow FASTA_PROCESS_REFERENCE_ALL {
    take:
    reference_selection           // string
    ch_reads                      // channel: [ val(meta), fastq ]
    ref_path                      // channel: [ val(meta), fasta ]

    main:
    ch_versions = Channel.empty()

    if (reference_selection == "static") {
        ref = tuple([id:ref_path.split("/")[-1].split("\\.")[0]], ref_path) // channel: [ val(meta), fasta ]
    } else if (reference_selection == "mapping") {
        //TODO
    } else {
        {exit 1, "invalid value supplied for variable 'reference_selection' !"}
    }

    PREPARE_REFERENCE(
        ref
    ).preped_ref
    | set {ch_preped_ref}

    ch_versions = ch_versions.mix(PREPARE_REFERENCE.out.versions.first())

    SAMTOOLS_FAIDX(
        ch_preped_ref,
        [[],[]]
    ).fai
    | set {ch_fai_index}

    ch_versions = ch_versions.mix(SAMTOOLS_FAIDX.out.versions.first())

    BWA_INDEX(
        ch_preped_ref
    ).index
    | set {ch_bwa_index}

    ch_versions = ch_versions.mix(BWA_INDEX.out.versions)

    emit:
    preped_ref           = ch_preped_ref
    fai_index            = ch_fai_index
    bwa_index            = ch_bwa_index

    versions             = ch_versions

}

