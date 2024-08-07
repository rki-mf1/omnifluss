include { MINIMAP2_ALIGN as MINIMAP2_SEGMENT_DB } from '../../../modules/nf-core/minimap2/align/main'

workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools           // String
    ch_reads        // channel: [ val(meta), [ fastq ] ]
    ch_segment_db   // channel: [ val(meta), [ fasta ] ]


    main:
    ch_versions = Channel.empty()
    ch_paf      = Channel.empty()

    if (tools.split(',').contains('minimap2')) {
        MINIMAP2_SEGMENT_DB(
            ch_reads,
            ch_segment_db,
            false,
            [],
            false,
            false
        )
        ch_versions = ch_versions.mix(MINIMAP2_SEGMENT_DB.out.versions.first())
        ch_paf      = MINIMAP2_SEGMENT_DB.out.paf
    }

    emit:
    paf         = ch_paf            // channel: [ val(meta), [paf] ]
    versions    = ch_versions       // channel: [ versions.yml ]
}

