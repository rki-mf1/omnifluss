include { FASTQC                 } from '../../../modules/nf-core/fastqc/main'
include { FASTP                  } from '../../../modules/nf-core/fastp/main'

workflow FASTQ_QC_TRIMMING_ALL {
    take:
    tools     // string
    ch_reads  // channel: [ val(meta), fastq ]

    main:
    ch_trimmed_reads  = Channel.empty()
    ch_multiqc_files  = Channel.empty()
    ch_versions       = Channel.empty()

    // FASTQC
    if (tools.split(',').contains('fastqc')) {
        FASTQC (
            ch_reads
        )
        ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]})
        ch_versions = ch_versions.mix(FASTQC.out.versions.first())
    }

    // FASTP
    if (tools.split(',').contains('fastp')) {
        FASTP(
            ch_reads,
            [],
            false,
            false,
            false
        )
        ch_multiqc_files = ch_multiqc_files.mix(FASTP.out.json.collect{it[1]})
        ch_versions = ch_versions.mix(FASTP.out.versions.first())

        ch_trimmed_reads = FASTP.out.reads
    }

    emit:
    trimmed_reads     = ch_trimmed_reads  // channel: [ val(meta), fastq ]

    multiqc_files     = ch_multiqc_files  // channel: [ multiqc_files ]
    versions          = ch_versions       // channel: [ versions.yml ]

}
