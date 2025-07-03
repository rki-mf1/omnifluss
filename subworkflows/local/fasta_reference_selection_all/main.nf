include { KMA }                         from '../../../modules/local/inv_referenceSelection_kma/main'
include { INV_GET_TOP1_REFERENCE_GREP } from '../../../modules/local/inv_reference_selection_grep/main'
include { CAT_CAT }                     from '../../../modules/nf-core/cat/cat/main'
include { SEQKIT_GREP }                 from '../../../modules/nf-core/seqkit/grep/main.nf'
include { SEQKIT_REPLACE }              from '../../../modules/nf-core/seqkit/replace/main.nf'

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
    ch_versions                 = Channel.empty()
    ch_kma_spa                  = Channel.empty()
    ch_top1ids                  = Channel.empty()
    ch_top1fastas               = Channel.empty()
    ch_top1fastas_standardized  = Channel.empty()
    ch_final_topRefs            = Channel.empty()


    if (tools.split(',').contains('kma')) {

        /****************************************************************/
        /* STEP 1: Compute KMA alignment and ref ranking                */
        /****************************************************************/
        ch_kma_input = ch_reads.combine(ch_kma_index)
            .multiMap{meta_sample, reads, meta_segments, index ->
                def newMeta = meta_sample + [segment: meta_segments.id]
                ch_reads: [ newMeta, reads ]
                ch_kma_index: [ meta_segments, index ]
            }

        KMA(
            ch_kma_input.ch_reads,
            ch_kma_input.ch_kma_index,
            false,
            false
        )
        ch_versions = ch_versions.mix(KMA.out.versions.first())
        ch_kma_spa  = ch_kma_spa.mix(KMA.out.spa)

        /****************************************************************/
        /* STEP 2: Get ID of Top1 refrences                             */
        /****************************************************************/
        INV_GET_TOP1_REFERENCE_GREP(
            ch_kma_spa
        )
        ch_versions = ch_versions.mix(INV_GET_TOP1_REFERENCE_GREP.out.versions.first())
        ch_top1ids  = ch_top1ids.mix(INV_GET_TOP1_REFERENCE_GREP.out.txt)

        /****************************************************************/
        /* STEP 3: Get FASTA of Top1 refrences                          */
        /****************************************************************/
        ch_reference_db_fastas_cpy = ch_reference_db_fastas
            .map{ meta, fasta -> return [meta.id, meta, fasta] }

        ch_top1ids_cpy = ch_top1ids
            .map{ meta, top1txt -> return [meta.segment, meta, top1txt] }

        ch_seqkit_grep_input = ch_reference_db_fastas_cpy.cross(ch_top1ids_cpy)
            .multiMap{fasta_list, sample_list ->
                ch_segment: [ sample_list[1], fasta_list[2] ]
                pattern: sample_list[2]
            }

        SEQKIT_GREP(
            ch_seqkit_grep_input.ch_segment,
            ch_seqkit_grep_input.pattern
        )
        ch_versions     = ch_versions.mix(SEQKIT_GREP.out.versions.first())
        ch_top1fastas   = ch_top1fastas.mix(SEQKIT_GREP.out.filter)

        /****************************************************************/
        /* STEP 4: Patch FASTA header Top1 refrences                    */
        /****************************************************************/
        SEQKIT_REPLACE(
            ch_top1fastas
        )
        ch_versions                 = ch_versions.mix(SEQKIT_REPLACE.out.versions.first())
        ch_top1fastas_standardized  = ch_top1fastas_standardized.mix(SEQKIT_REPLACE.out.fastx)

        /****************************************************************/
        /* STEP 5: Concat FASTAs of Top1 refrences                      */
        /****************************************************************/
        ch_top1fastas_standardized
            .map{ meta, fasta -> return [[id:meta.id, single_end:meta.single_end], fasta] }
            .groupTuple()
            .set{ ch_top1fastas_standardized }

        CAT_CAT(
            ch_top1fastas_standardized
        )
        ch_versions         = ch_versions.mix(CAT_CAT.out.versions.first())
        ch_final_topRefs    = CAT_CAT.out.file_out

    } else {

        {exit 1, "Invalid tool name supplied for reference selection!"}

    }


    emit:
    spa                 = ch_kma_spa            // channel: [ val(meta), [file(spa)] ]      // nf-core style
    top1ids             = ch_top1ids            // channel: [ val(meta), file(txt) ]        // nf-core style
    final_topRefs       = ch_final_topRefs      // channel: [ val(meta), fasta ]            // nf-core style
    versions            = ch_versions           // channel: [ versions.yml ]
}

