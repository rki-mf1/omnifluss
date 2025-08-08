include { KRAKEN2_KRAKEN2                   } from '../../../modules/nf-core/kraken2/kraken2/main'
include { KRAKENTOOLS_EXTRACTKRAKENREADS    } from '../../../modules/nf-core/krakentools/extractkrakenreads/main'


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

    if (tools.split(',').contains('kraken2')) {

        // KRAKEN
        KRAKEN2_KRAKEN2 ( ch_reads, ch_db, true, true )
        _ch_classified_reads_assignment = KRAKEN2_KRAKEN2.out.classified_reads_assignment
        _ch_classified_reads_fastq      = KRAKEN2_KRAKEN2.out.classified_reads_fastq
        ch_kraken2_report               = KRAKEN2_KRAKEN2.out.report
        ch_multiqc_files                = ch_kraken2_report.map{it[1]}
        ch_versions                     = ch_versions.mix(KRAKEN2_KRAKEN2.out.versions)

        // filter empty files
        def isFastqEmptyFunction = branchCriteria {_meta, reads ->
            boolean isEmpty = (_meta.single_end) ? FileCheck.isFileEmpty(reads.toFile()) : FileCheck.isFileEmpty(reads[0].toFile()) && FileCheck.isFileEmpty(reads[1].toFile())
            empty: isEmpty
            nonempty: !isEmpty
        }

        // Scenario: KRAKEN returns empty FASTQ files because no reads got assigned with any given taxID
        _ch_classified_reads_fastq = _ch_classified_reads_fastq.branch(isFastqEmptyFunction)

        // KRAKENTOOLS
        KRAKENTOOLS_EXTRACTKRAKENREADS ( val_taxid, _ch_classified_reads_assignment, _ch_classified_reads_fastq.nonempty, ch_kraken2_report )
        ch_extracted_kraken2_reads = KRAKENTOOLS_EXTRACTKRAKENREADS.out.extracted_kraken2_reads
        ch_versions                = ch_versions.mix(KRAKENTOOLS_EXTRACTKRAKENREADS.out.versions)

        // filter empty files
        // Scenario: KRAKEN returned non-empty FASTQ files but all reads were assigned to off-target species w.r.t. taxIDs given to KRAKENTOOLS'
        ch_extracted_kraken2_reads = ch_extracted_kraken2_reads.branch(isFastqEmptyFunction)
    }

    emit:

    kraken2_report          = ch_kraken2_report
    extracted_kraken2_reads = ch_extracted_kraken2_reads.nonempty
    multiqc_files           = ch_multiqc_files
    versions                = ch_versions

}
