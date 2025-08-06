include { FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS } from '../../nf-core/fastq_extract_kraken_krakentools/main'

workflow FASTQ_TAXONOMIC_FILTERING_ALL {
    take:
    tools               // string
    ch_reads            // channel: [ val(meta), path(reads) ]
    ch_db               // channel: [ path db ]
    val_taxid           // string

    main:
    ch_kraken2_report           = Channel.empty()
    ch_extracted_kraken2_reads  = Channel.empty()
    ch_multiqc_files            = Channel.empty()
    ch_versions                 = Channel.empty()

    if (tools.split(',').contains('kraken2')) {
        FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS(
            ch_reads,
            ch_db,
            val_taxid
        )
        ch_kraken2_report          = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.kraken2_report
        ch_extracted_kraken2_reads = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.extracted_kraken2_reads
        ch_multiqc_files           = ch_multiqc_files.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.multiqc_files.collect())
        ch_versions                = ch_versions.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.versions)
    }

    // Filter all samples with no reads in at least one FASTQ file (to consider single-end/ paired-end NGS) of taxonomically classified reads.
    // Mind the return logic: filter{} emits only items where the condition is true.
    ch_extracted_kraken2_reads = ch_extracted_kraken2_reads.filter { _meta, reads ->
        boolean firstInPairEmpty  = FileCheck.isFileEmpty(reads[0].toFile())
        boolean secondInPairEmpty = (reads.size() > 1) ? FileCheck.isFileEmpty(reads[1].toFile()) : false
        return !firstInPairEmpty && !secondInPairEmpty
    }

    emit:
    kraken2_report          = ch_kraken2_report                 // channel: [ val(meta), report ]
    extracted_kraken2_reads = ch_extracted_kraken2_reads        // channel: [ val(meta), fastq/fasta ]

    multiqc_files     = ch_multiqc_files                        // channel: [ val(meta), report ]
    versions          = ch_versions                             // channel: [ versions ]

}
