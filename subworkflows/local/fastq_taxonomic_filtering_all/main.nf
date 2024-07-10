include { FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS } from '../../nf-core/fastq_extract_kraken_krakentools/main'

workflow FASTQ_TAXONOMIC_FILTERING_ALL {
    take:
    ch_reads
    ch_db
    val_taxid

    main:
    ch_kraken2_report           = Channel.empty()
    ch_extracted_kraken2_reads  = Channel.empty()
    
    FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS(
        ch_reads,
        ch_db,
        val_taxid
    )

    ch_kraken2_report = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.kraken2_report
    ch_extracted_kraken2_reads = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.extracted_kraken2_reads
    multiqc_files = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.multiqc_files
    versions = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.versions

    emit:
    ch_kraken2_report = ch_kraken2_report
    ch_extracted_kraken2_reads = ch_extracted_kraken2_reads

    multiqc_files     = multiqc_files
    versions          = versions

}
