include { KRAKEN2_KRAKEN2                } from '../../../modules/nf-core/kraken2/kraken2/main'
include { KRAKENTOOLS_EXTRACTKRAKENREADS } from '../../../modules/nf-core/krakentools/extractkrakenreads/main'

workflow FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS {

    take:
    ch_reads   // channel: [ val(meta), fastq ]
    val_db     // string
    val_taxid  // string

    main:
    ch_versions = Channel.empty()

    KRAKEN2_KRAKEN2 ( ch_reads, val_db, true, true )
    ch_versions = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions.first())

    KRAKENTOOLS_EXTRACTKRAKENREADS ( val_taxid, KRAKEN2_KRAKEN2.out.classified_reads_assignment, KRAKEN2_KRAKEN2.out.classified_reads_fastq, KRAKEN2_KRAKEN2.out.report )
    ch_versions = ch_versions.mix( KRAKENTOOLS_EXTRACTKRAKENREADS.out.versions.first() )

    emit:
    kraken2_report = KRAKEN2_KRAKEN2.out.report                                          // channel: [ val(meta), path ]
    extracted_kraken2_reads = KRAKENTOOLS_EXTRACTKRAKENREADS.out.extracted_kraken2_reads // channel: [ val(meta), [ fastq/fasta ] ]
    multiqc_files = KRAKEN2_KRAKEN2.out.report                                           // channel: [ val(meta), path ]
    versions = ch_versions                                                               // channel: [ versions.yml ]
}
