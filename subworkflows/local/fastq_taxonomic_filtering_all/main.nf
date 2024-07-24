include { FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS } from '../../nf-core/fastq_extract_kraken_krakentools/main'

workflow FASTQ_TAXONOMIC_FILTERING_ALL {
    take:
    tools
    ch_reads
    ch_db
    val_taxid

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

        ch_kraken2_report = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.kraken2_report
        ch_extracted_kraken2_reads = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.extracted_kraken2_reads
        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.multiqc_files)
        ch_versions = ch_versions.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.versions)
    }

    emit:
    kraken2_report = ch_kraken2_report
    extracted_kraken2_reads = ch_extracted_kraken2_reads

    multiqc_files     = ch_multiqc_files
    versions          = ch_versions

}
