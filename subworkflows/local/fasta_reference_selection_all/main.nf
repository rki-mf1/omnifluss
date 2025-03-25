include { KMA }                         from '../../../modules/local/inv_referenceSelection_kma/main'
include { INV_GET_TOP1_REFERENCE_GREP } from '../../../modules/local/inv_reference_selection_grep/main'
include { CAT_CAT as CAT_CAT1}          from '../../../modules/nf-core/cat/cat/main'
include { CAT_CAT as CAT_CAT2}          from '../../../modules/nf-core/cat/cat/main'
include { SEQKIT_GREP }                 from '../../../modules/nf-core/seqkit/grep/main.nf'

/*
    TECHNICAL DESCRIPTION
    ----
    Input:
        - tools:
            - only option is "kma" at the moment
        - ch_reads:
            - nf-core style tuple channel with PE NGS reads
        - ch_reference_db_fastas:
            - genome/chromosome/segment FASTA file(s) to select best matching reference(s) from
        - ch_kma_index:
            - kma index files of the FASTAs in ch_reference_db_fastas
    Output:
        - ch_final_topRefs:
            - This is the most important output Channel. It contains the closest reference(s) per sample (i.e. readpairs in ch_reads).
*/


workflow FASTA_REFERENCE_SELECTION_ALL {

    take:
    tools                   // String
    ch_reads                // channel: [ val(meta), [ fastq ] ]
    ch_reference_db_fastas  // channel: [ val(meta), [ fasta ] ]
    ch_kma_index            // channel: [ val(meta), [ kma_index ] ]

    main:
    ch_versions         = Channel.empty()
    ch_kma_spa          = Channel.empty()
    ch_top1ids          = Channel.empty()
    ch_top1fastas       = Channel.empty()
    ch_final_topRefs    = Channel.empty()


    if (tools.split(',').contains('kma')) {

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
        ch_kma_spa  = ch_kma_spa.mix(KMA.out.spa)

        /****************************************************************/
        /* STEP 2: Get ID of Top1 refrence(s)                           */
        /****************************************************************/
        INV_GET_TOP1_REFERENCE_GREP(
            ch_kma_spa
        )
        ch_versions = ch_versions.mix(INV_GET_TOP1_REFERENCE_GREP.out.versions.first())
        ch_top1ids  = ch_top1ids.mix(INV_GET_TOP1_REFERENCE_GREP.out.txt)

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
        /*
        ch_kma_index
            .map { meta, index_files ->
                def fasta = index_files.findAll {
                    it.toString().endsWith(".fa") ||
                    it.toString().endsWith(".fasta") ||
                    it.toString().endsWith(".fa.gz") ||
                    it.toString().endsWith(".fasta.gz")
                }
                return [meta, fasta]
            }
            .set { ch_reference_db_fastas }
        */

        pattern = ch_top1ids.map { _meta, file -> return file }      // need only the file here for SEQKIT_GREP
        SEQKIT_GREP(
            ch_reference_db_fastas,
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


    emit:
    spa                 = ch_kma_spa            // channel: [ val(meta), [file(spa)] ]      // nf-core style
    top1ids             = ch_top1ids            // channel: [ val(meta), file(txt) ]        // nf-core style
    final_topRefs       = ch_final_topRefs      // channel: [ val(meta), fasta ]            // nf-core style
    versions            = ch_versions           // channel: [ versions.yml ]
}

