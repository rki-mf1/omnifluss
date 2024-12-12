include { KMA_INDEX }       from '../../../modules/local/inv_referenceSelection_kmaIndex/main'
include { KMA }             from '../../../modules/local/inv_referenceSelection_kma/main'
include { TOP1_REFERENCE }  from '../../../modules/local/inv_referenceSelection_grep/main'
include { CAT_CAT }         from '../../../modules/nf-core/cat/cat/main'
include { SEQKIT_GREP }     from '../../../modules/nf-core/seqkit/grep/main.nf'

workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools                   // String
    reference_selection     // String
    reference_db_path       // String
    ch_reads                // channel: [ val(meta), [ fastq ] ]


    main:
    ch_versions     = Channel.empty()
    ch_kma_index    = Channel.empty()
    ch_kma          = Channel.empty()
    ch_top1ids      = Channel.empty()


    if (reference_selection == "static") {

        // TODO
        //ref = tuple([id:file(params.fasta).getSimpleName()], ref_path) // channel: [ val(meta), fasta ]

    } else if (reference_selection == "mapping") {

        if (tools.split(',').contains('kma')) {
        
            /****************************************************************/
            /* STEP 0: Check if KMA index files exist                       */
            /*      If true, load the index files                           */
            /*      If false, compute the KMA index                         */
            /****************************************************************/

            kma_index_files = file(reference_db_path + '*.{comp.b,length.b,name,seq.b}')

            // Check that list of input files is not empty and every file is non-zero bytes
            if (kma_index_files && kma_index_files.every { file -> file.exists() && file.size() > 0 }) {
                println "Index files found."

                // Generate the ch_kma_index channel from kma_index_files
                ch_segment_files    = Channel.fromPath(kma_index_files, checkIfExists: true)
                ch_segment_files
                    .map { file ->
                        def prefix = file.name.tokenize('.')[0]     // Extract prefix before the first "."
                        return [prefix, file]                       // Return a tuple with prefix and file
                    }
                    .groupTuple()                                   // Group by the first element (prefix)
                    .map { prefix, files ->
                        return [[id: prefix], files]                // Create the desired output format
                    }
                    .set { ch_kma_index }
                ch_kma_index.view()

            }
            else {
                println "Generating index files."
                
                // Build channel of references
                ch_segment_files    = Channel.fromPath(reference_db_path + '**.{fasta,fa}', checkIfExists: true)
                ch_segment_files
                    .map { file ->
                        def prefix = file.name.tokenize('.')[0]
                        return [ [ id: prefix], file]
                        }
                    .set { ch_segment_db }
                ch_segment_db.view()

                // Building KMA index
                KMA_INDEX(
                    ch_segment_db
                )
                ch_versions     = ch_versions.mix(KMA_INDEX.out.versions.first())
                ch_kma_index     = KMA_INDEX.out.db
            }

            /****************************************************************/
            /* STEP 1: Compute KMA alignment and ref ranking                */
            /****************************************************************/
            KMA(
                ch_reads,
                ch_kma_index,
                false,
                false
            )
            ch_versions = ch_versions.mix(KMA.out.versions.first())
            ch_kma      = ch_kma.mix(KMA.out.spa)

            /****************************************************************/
            /* STEP 2: Get ID of Top1 refrence(s)                           */
            /****************************************************************/
            TOP1_REFERENCE(
                ch_kma
            )
            ch_versions = ch_versions.mix(KMA.out.versions.first())
            ch_top1ids  = ch_top1ids.mix(TOP1_REFERENCE.out.txt)


            // Generate a nf-core style input channel:
            //      tuple val(meta), path(txt)
            // where meta contains the map of ch_reads and path(txt) is a list of all top1id files.
            ch_top1ids.map { tuple ->
                def txtfile = tuple[1]
                return txtfile
            }
            .collect()
            .map { top1ids ->
                [ch_reads[0], top1ids]
            }
            .set{ ch_top1ids }


            CAT_CAT(
                ch_top1ids
            )
            ch_versions = ch_versions.mix(CAT_CAT.out.versions.first())
            ch_top1ids  = CAT_CAT.out.file_out


            /****************************************************************/
            /* STEP 3: Get FASTA of Top1 refrences                          */
            /****************************************************************/
            /*
            SEQKIT_GREP(
                X,
                Y
            )
            ch_versions = ch_versions.mix(SEQKIT_GREP.out.versions.first())
            ch_XYZ  = ch_top1ids.mix(todo)
            */

        } else {

            {exit 1, "Invalid tool name supplied for reference selection!"}

        }

    } else {

        {exit 1, "Invalid value supplied for variable 'reference_selection' !"}

    }

    emit:
    index               = ch_kma_index      // channel: [ val(meta), [db] ]
    kma                 = ch_kma            // channel: [ val(meta), spa ]
    //top1ids_readmeta    = ch_top1ids_readmeta
    top1ids             = ch_top1ids        // channel: [ val(meta), txt ]
    //top1ids_nfcore      = ch_top1ids_nfcore
    //allids              = ch_allids
    versions            = ch_versions       // channel: [ versions.yml ]
}

