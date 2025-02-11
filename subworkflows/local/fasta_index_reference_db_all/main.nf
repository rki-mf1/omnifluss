include { KMA_INDEX }           from '../../../modules/local/inv_referenceSelection_kmaIndex/main'

workflow FASTA_INDEX_REFERENCE_DB_ALL {

    take:
    tools               // {"kma"}
    reference_db_path   // String


    main:
    ch_kma_index    = Channel.empty()
    ch_versions     = Channel.empty()

    if (tools.split(',').contains('kma')) {

        fasta_files = file(reference_db_path + '*.{fa,fa.gz,fasta,fasta.gz}')

        // Sanity checks
        if (!fasta_files){
            {exit 1, "No FASTA files found in reference db path."}
        }
        if (fasta_files.any { file.size() == 0 }){
            {exit 1, "At least one FASTA reference file is empty."}
        }

        // Check if KMA index is present
        kma_index_files = file(reference_db_path + '*.{comp.b,length.b,name,seq.b}')
        kma_index_present = kma_index_files && kma_index_files.every { file -> file.exists() && file.size() > 0 }

        if (kma_index_present){
            all_files = fasta_files + kma_index_files

            Channel
                .fromPath(all_files, checkIfExists: true)
                .map { file ->
                    def prefix = file.simpleName    // Extract prefix before the first "."
                    return [prefix, file]
                }
                .groupTuple()   // Group tuples by the first element (prefix)
                .map { prefix, files ->
                    return [[id: prefix], files]    // Create the nf-core meta map format
                }
                .set { ch_kma_index }
        }
        else {
            Channel
                .fromPath(fasta_files, checkIfExists: true)
                .map { file ->
                    def prefix = file.simpleName    // Extract prefix before the first "."
                    return [ [ id: prefix], file]
                    }
                .set { ch_reference_fastas }

                KMA_INDEX(
                    ch_reference_fastas
                )
                ch_versions     = ch_versions.mix(KMA_INDEX.out.versions.first())
                // TODO: to be test once KMA_INDEX is in dev branch
                ch_kma_index    = KMA_INDEX.out.db
                                    .collect()
                                    .join(ch_reference_fastas)
                                    .groupTuple()

        }

    }


    emit:
    kma_index   = ch_kma_index              // channel: [meta, path(kma_index)]
    versions    = ch_versions               // channel: [ versions.yml ]
}

