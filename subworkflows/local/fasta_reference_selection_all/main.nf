include { KMA_INDEX } from '../../../modules/local/inv_referenceSelection_kmaIndex/main'
include { KMA }       from '../../../modules/local/inv_referenceSelection_kma/main'

workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools                   // String
    reference_selection     // String
    reference_db_path       // String
    ch_reads                // channel: [ val(meta), [ fastq ] ]


    main:
    ch_versions     = Channel.empty()
    ch_kma_db       = Channel.empty()


    if (reference_selection == "static") {

        // TODO
        //ref = tuple([id:file(params.fasta).getSimpleName()], ref_path) // channel: [ val(meta), fasta ]

    } else if (reference_selection == "mapping") {
        // ********** STEP 0: Build channel of references **********
        ch_segment_files    = Channel.fromPath(reference_db_path + '**.{fasta,fa}', checkIfExists: true)
        ch_segment_files
            .map { file ->
                def prefix = file.name.tokenize('.')[0] // Extract prefix before the first "."
                return [ [ id: prefix], file]
            }
            .set { ch_segment_db }
        ch_segment_db.view()

        if (tools.split(',').contains('kma')) {
            // ********** STEP 1: Building kma index **********
            KMA_INDEX(
                ch_segment_db
            )
            ch_versions     = ch_versions.mix(KMA_INDEX.out.versions.first())
            ch_kma_db       = KMA_INDEX.out.db

            // ********** STEP 2: Map reads with kma and score references **********
            KMA(
                ch_reads,
                ch_kma_db,
                false,
                false
            )
            ch_versions     = ch_versions.mix(KMA.out.versions.first())
        }


    } else {

        {exit 1, "invalid value supplied for variable 'reference_selection' !"}

    }

    emit:
    kma_index   = ch_kma_db         // channel: [ val(meta), [db] ]
    versions    = ch_versions       // channel: [ versions.yml ]
}

