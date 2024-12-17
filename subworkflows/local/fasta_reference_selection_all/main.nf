include { KMA_INDEX }           from '../../../modules/local/inv_referenceSelection_kmaIndex/main'
include { KMA }                 from '../../../modules/local/inv_referenceSelection_kma/main'
include { TOP1_REFERENCE }      from '../../../modules/local/inv_referenceSelection_grep/main'
include { CAT_CAT as CAT_CAT1}  from '../../../modules/nf-core/cat/cat/main'
include { CAT_CAT as CAT_CAT2}  from '../../../modules/nf-core/cat/cat/main'
include { SEQKIT_GREP }         from '../../../modules/nf-core/seqkit/grep/main.nf'

/*
    INFO
    ----
    Input:
        - reference_db_path:
            - Every reference file is uniquely identifyable before the first appearance of '.'
            - Every reference file is not empty
    Output:
        - ch_final_topRefs:
            - This is the most important output Channel. It contains the closest reference(s)
              per sample (i.e. readpair in ch_reads).
*/


workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools                   // String
    reference_selection     // String
    reference_db_path       // String
    ch_reads                // channel: [ val(meta), [ fastq ] ]        // nf-core style


    main:
    ch_versions         = Channel.empty()
    ch_kma_index        = Channel.empty()
    ch_kma              = Channel.empty()
    ch_top1ids          = Channel.empty()
    ch_reference_fastas = Channel.empty()
    ch_top1fastas       = Channel.empty()
    ch_final_topRefs    = Channel.empty()


    if (reference_selection == "static") {

        // TODO
        /*
        @krannich479:   What's the format we expect if the refence selectin is 'static'?
                        I prototyped a solution below where we'd expect the input
                        reference_db_path to be one (multi-)FASTA file.
        */

        // ch_final_topRefs = tuple([id: ch_reads[0].id + '.staticRef'], reference_db_path)     // channel: [ val(meta), fasta ]

    } else if (reference_selection == "mapping") {
        println "Automated reference selection."

        if (tools.split(',').contains('kma')) {
        
            /****************************************************************/
            /* STEP 0:  Check if KMA index files exist.                     */
            /*          If true, load the index files                       */
            /*          If false, compute the KMA index                     */
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
                        return [[id: prefix], files]                // Create the nf-core meta map format
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
                ch_kma_index    = KMA_INDEX.out.db
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
            ch_versions = ch_versions.mix(TOP1_REFERENCE.out.versions.first())
            ch_top1ids  = ch_top1ids.mix(TOP1_REFERENCE.out.txt)

            // Generate a nf-core style input channel:
            //      tuple val(meta), path(txt)
            // where meta contains the map of ch_reads and path(txt) is a list of all top1id txt files.
            ch_top1ids.map { tuple ->
                def txtfile = tuple[1]
                return txtfile
            }
            .collect()
            .map { top1ids ->
                [ch_reads[0], top1ids]
            }
            .set{ ch_top1ids }

            CAT_CAT1(
                ch_top1ids
            )
            ch_versions = ch_versions.mix(CAT_CAT1.out.versions.first())
            ch_top1ids  = CAT_CAT1.out.file_out

            /****************************************************************/
            /* STEP 3: Get FASTA of Top1 refrence(s)                        */
            /****************************************************************/
            Channel
                .fromPath(
                    reference_db_path + '*.{fa,fasta}',
                    checkIfExists: true,
                    hidden: false,
                    followLinks: true)
                .map { fasta ->
                    def prefix = fasta.name.tokenize('.')[0]
                    return [prefix, fasta]
                }
                .groupTuple()
                .map{ prefix, fastas ->
                    return [[id: prefix], fastas]
                }
                .set { ch_reference_fastas }

            pattern = ch_top1ids.map { meta, file -> return file }      // need only the file here for SEQKIT_GREP
            SEQKIT_GREP(
                ch_reference_fastas,
                pattern
            )
            ch_versions     = ch_versions.mix(SEQKIT_GREP.out.versions.first())
            ch_top1fastas   = ch_top1fastas.mix(SEQKIT_GREP.out.filter)

            // Generate a nf-core style input channel:
            //      tuple val(meta), path(fasta)
            // where meta contains the map of ch_reads and path(fasta) is a list of all top1-sequence fasta files.
            ch_top1fastas.map { tuple ->
                def fasta = tuple[1]
                return fasta
            }
            .collect()
            .map { top1fastas ->
                [[id: ch_reads[0].id + '.topRef' ], top1fastas]
            }
            .set{ ch_top1fastas }

            CAT_CAT2(
                ch_top1fastas
            )
            ch_final_topRefs  = CAT_CAT2.out.file_out


        } else {

            {exit 1, "Invalid tool name supplied for reference selection!"}

        }

    } else {

        {exit 1, "Invalid value supplied for variable 'reference_selection' !"}

    }

    emit:
    index               = ch_kma_index          // channel: [ val(meta), [db] ]             // nf-core style
    kma                 = ch_kma                // channel: [ val(meta), file(spa) ]        // nf-core style
    top1ids             = ch_top1ids            // channel: [ val(meta), file(txt) ]        // nf-core style
    reference_fastas    = ch_reference_fastas   // channel: [ val(meta), file(fasta) ]      // nf-core style
    //top1fastas          = ch_top1fastas         // channel: [ val(meta), [fasta] ]          // nf-core style
    final_topRefs       = ch_final_topRefs      // channel: [ val(meta), fasta ]            // nf-core style
    versions            = ch_versions           // channel: [ versions.yml ]
}

