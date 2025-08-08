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

    _ch_classified_reads_assignment = Channel.empty()
    _ch_classified_reads_fastq      = Channel.empty()
    _ch_kraken2_report              = Channel.empty()

    if (tools.split(',').contains('kraken2')) {

        // KRAKEN
        KRAKEN2_KRAKEN2 ( ch_reads, ch_db, true, true )
        _ch_classified_reads_assignment = KRAKEN2_KRAKEN2.out.classified_reads_assignment
        _ch_classified_reads_fastq      = KRAKEN2_KRAKEN2.out.classified_reads_fastq
        _ch_kraken2_report              = KRAKEN2_KRAKEN2.out.report
        ch_versions                     = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)

        // filter empty files
        def isFastqEmptyFunctor = branchCriteria {_meta, reads ->
            boolean firstInPairEmpty        = FileCheck.isFileEmpty(reads[0].toFile())
            boolean secondInPairEmpty       = (reads.size() > 1) ? FileCheck.isFileEmpty(reads[1].toFile()) : false
            boolean atLeastOneFastqEmpty    = firstInPairEmpty || secondInPairEmpty
            // Here, the empty file channel can be used for logging/reporting
            empty: atLeastOneFastqEmpty
            nonempty: !atLeastOneFastqEmpty
        }

        // Scenario: KRAKEN returns empty FASTQ files because no reads got assigned with any given taxID
        _ch_classified_reads_fastq = _ch_classified_reads_fastq.branch(isFastqEmptyFunctor)

        // KRAKENTOOLS
        KRAKENTOOLS_EXTRACTKRAKENREADS ( val_taxid, _ch_classified_reads_assignment, _ch_classified_reads_fastq.nonempty, _ch_kraken2_report )
        ch_kraken2_report          = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.kraken2_report
        ch_extracted_kraken2_reads = FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.extracted_kraken2_reads
        ch_multiqc_files           = ch_multiqc_files.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.multiqc_files.collect())
        ch_versions                = ch_versions.mix(FASTQ_EXTRACT_KRAKEN_KRAKENTOOLS.out.versions)

        // filter empty files
        // Scenario: KRAKEN returned non-empty FASTQ files but all reads were assigned to off-target species w.r.t. taxIDs given to KRAKENTOOLS' 
        ch_extracted_kraken2_reads = ch_extracted_kraken2_reads.branch(isFastqEmptyFunctor)
    }

    emit:

    kraken2_report          = ch_kraken2_report
    extracted_kraken2_reads = ch_extracted_kraken2_reads.nonempty
    multiqc_files           = ch_multiqc_files
    versions                = ch_versions

}
