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
        def isFastqEmptyFunction = branchCriteria {meta, reads ->
            boolean isEmpty
            boolean failedSizeCheck

            if (meta.single_end) {
                if (file(reads).size() == 0){                                                               //filter out files of size 0, otherwise countFastq() crashes
                    isEmpty = true
                } else {
                    failedSizeCheck = file(reads).size() < 500                                              //prefilter files with a small number of reads for counting
                    isEmpty = (failedSizeCheck) ? file(reads).countFastq() == 0: failedSizeCheck
                }
            } else {
                if (file(reads[0]).size() == 0 && file(reads[1]).size() == 0){
                    isEmpty = true
                } else {
                    failedSizeCheck = file(reads[0]).size() < 500 && file(reads[1]).size() < 500
                    isEmpty = (failedSizeCheck) ? file(reads[0]).countFastq() == 0  && file(reads[1]).countFastq() == 0: failedSizeCheck
                }
            }
            empty: isEmpty
            nonempty: !isEmpty
        }

        // Scenario: KRAKEN returns empty FASTQ files because no reads got assigned with any given taxID
        _ch_classified_reads_fastq = _ch_classified_reads_fastq.branch(isFastqEmptyFunction)

        // sort inputs
        _ch_classified_reads_assignment_cpy     = _ch_classified_reads_assignment.map{ meta, assignment -> return [meta.id, meta, assignment ] }
        _ch_classified_reads_fastq_nonempty_cpy = _ch_classified_reads_fastq.nonempty.map{ meta, fastq -> return [meta.id, meta, fastq ] }
        ch_kraken2_report_cpy                   = ch_kraken2_report.map{ meta, report -> return [meta.id, meta, report] }

        ch_krakentools_extract_krakenreads_input = _ch_classified_reads_assignment_cpy.join(_ch_classified_reads_fastq_nonempty_cpy).join(ch_kraken2_report_cpy)
            .multiMap{ _sample_id, meta, assignment, meta2, fastq, meta3, report ->
                ch_assignment: [meta, assignment]
                ch_reads: [meta2, fastq]
                ch_report: [meta3, report]
                }

        // KRAKENTOOLS
        KRAKENTOOLS_EXTRACTKRAKENREADS ( 
            val_taxid, 
            ch_krakentools_extract_krakenreads_input.ch_assignment, 
            ch_krakentools_extract_krakenreads_input.ch_reads, 
            ch_krakentools_extract_krakenreads_input.ch_report
        )
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
