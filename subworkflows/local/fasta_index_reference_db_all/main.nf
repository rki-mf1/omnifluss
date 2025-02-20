include { KMA_INDEX }   from '../../../modules/nf-core/kma/index/main'

workflow FASTA_INDEX_REFERENCE_DB_ALL {

    take:
    tools                   // String
    reference_db_path       // String


    main:
    ch_reference_db_fastas  = Channel.empty()
    ch_kma_index            = Channel.empty()
    ch_versions             = Channel.empty()

    if (tools.split(',').contains('kma')) {

        def fasta_files = file("$reference_db_path/*.{fa,fa.gz,fasta,fasta.gz}")
        println fasta_files
        println fasta_files.size()
        // Sanity checks
        assert fasta_files.size() > 0 : "Error: No FASTA files found in reference database path."
        assert fasta_files.every{ file -> file.size() > 0 } : "Error: At least one FASTA reference file is empty."

        Channel
            .fromPath(fasta_files, checkIfExists: true)
            .map { file ->
                def prefix = file.simpleName        // Extract prefix before the first "."
                return [[id: prefix], file]
            }
            .set { ch_reference_db_fastas }

        // Try find index files if present
        def kma_index_files     = file("$reference_db_path/*.{comp.b,length.b,name,seq.b}")
        println kma_index_files
        println kma_index_files.size()
        def kma_index_present   = kma_index_files.size() != 0

        // Create index if not present
        if (kma_index_present){

            // Sanity checks
            assert kma_index_files.every{ file -> file.size() > 0 } : "Error: At least one KMA index file is empty."
            assert 4*fasta_files.size() == kma_index_files.size() : "Error: Unexpected number of KMA index files."

            Channel
                .fromPath(kma_index_files, checkIfExists: true)
                .map { file ->
                    def prefix = file.simpleName    // Extract prefix before the first "."
                    return [prefix, file]
                }
                .groupTuple()                       // Group tuples by the first element (prefix)
                .map { prefix, files ->
                    return [[id: prefix], files]    // Create the nf-core meta map format
                }
                .set { ch_kma_index }
        }
        else {

            KMA_INDEX(
                ch_reference_db_fastas
            )
            ch_kma_index    = ch_kma_index.mix(KMA_INDEX.out.index)
            ch_versions     = ch_versions.mix(KMA_INDEX.out.versions.first())
        }

    }


    emit:
    reference_db_fastas = ch_reference_db_fastas    // channel: [meta, fasta ]
    kma_index           = ch_kma_index              // channel: [meta, [kma_index] ]
    versions            = ch_versions               // channel: versions.yml
}

