include { MINIMAP2_ALIGN as MINIMAP2_SEGMENT_DB }   from '../../../modules/nf-core/minimap2/align/main'
include { TOP5_REFERENCES }                         from '../../../modules/local/inv_top5references_r/main'
include { SEQKIT_GREP }                             from '../../../modules/nf-core/seqkit/grep/main'
include { MINIMAP2_ALIGN as MINIMAP2_SEGMENT_TOP5 } from '../../../modules/nf-core/minimap2/align/main'


workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools                   // String
    reference_selection     // String
    ch_reads                // channel: [ val(meta), [ fastq ] ]
    ch_segment_db           // channel: [ val(meta), [ fasta ] ]


    main:
    ch_versions     = Channel.empty()
    ch_paf          = Channel.empty()
    ch_top5_txt     = Channel.empty()
    ch_top5_fasta   = Channel.empty()
    ch_top5_bam     = Channel.empty()

    if (reference_selection == "static") {

        // TODO
        //ref = tuple([id:file(params.fasta).getBaseName()], ref_path) // channel: [ val(meta), fasta ]

    } else if (reference_selection == "mapping") {

        // ********** STEP 1: Mapping reads to Ref DB **********
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

        // ********** STEP 2: Get top5 reference IDs **********
        TOP5_REFERENCES(ch_paf)
        ch_versions     = ch_versions.mix(TOP5_REFERENCES.out.versions.first())
        ch_top5_txt     = TOP5_REFERENCES.out.txt
        top5_file_str   = ch_top5_txt.map{ it[1] }  // string; required by nf-core SEQKIT_GREP

        // ********** STEP 3: Get top5 reference sequences by ID **********
        SEQKIT_GREP(
            ch_segment_db,
            top5_file_str
        )
        ch_versions     = ch_versions.mix(SEQKIT_GREP.out.versions.first())
        ch_top5_fasta   = SEQKIT_GREP.out.filter

        // ********** STEP 4: Re-mapping reads to top5 reference sequences **********
        if (tools.split(',').contains('minimap2')) {
            MINIMAP2_SEGMENT_TOP5(
                ch_reads,
                ch_top5_fasta,
                true,
                [],
                false,
                false
            )
        }
        ch_versions = ch_versions.mix(MINIMAP2_SEGMENT_TOP5.out.versions.first())
        ch_top5_bam = MINIMAP2_SEGMENT_DB.out.bam


    } else {

        {exit 1, "invalid value supplied for variable 'reference_selection' !"}

    }

    emit:
    //paf       = ch_paf            // channel: [ val(meta), [paf] ]
    //top5ids   = ch_top5_txt       // channel: [ val(meta), [txt] ]
    top5fasta   = ch_top5_fasta     // channel: [ val(meta), [fasta] ]
    top5bam     = ch_top5_bam       // channel: [ val(meta), [bam] ]
    versions    = ch_versions       // channel: [ versions.yml ]
}

