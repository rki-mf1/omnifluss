/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { FASTQ_QC_TRIMMING_ALL  } from '../subworkflows/local/fastq_qc_trimming_all'
include { FASTP_MAP_ALL          } from '../subworkflows/local/fastq_map_all'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-validation'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_igsmp_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow IGSMP {

    take:
    ch_samplesheet // channel: samplesheet read in from --input

    main:
    ch_reads = ch_samplesheet
    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()

    //
    // Read QC
    //
    if (! params.skip_read_qc) {
        FASTQ_QC_TRIMMING_ALL(
            params.read_qc,
            ch_reads
        )
        .trimmed_reads
        | set {ch_reads}

        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_TRIMMING_ALL.out.multiqc_files.collect{it[1]})
        ch_versions = ch_versions.mix(FASTQ_QC_TRIMMING_ALL.out.versions.first())
    }

    //
    // Taxonomic classification
    //
    // if (! params.skip_taxonomic_filtering) {
    //     FASTQ_TAXONOMIC_FILTERING_ALL(
    //         params.taxonomic_classifier,
    //         params.kraken2_db,
    //         params.kraken2_taxid_filter_list,
    //         ch_reads
    //     )
    //     .filtered_reads
    //     | set {ch_reads}
    //     ch_multiqc_files = ch_multiqc_files.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.multiqc_files.collect{it[1]})
    //     ch_versions = ch_versions.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.versions.first())
    // }

    //
    // Reference selection
    //
    // FASTA_SELECT_REFERENCE_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(FASTA_SELECT_REFERENCE_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(FASTA_SELECT_REFERENCE_ALL.out.versions.first())

    //
    // Mapping
    //
    FASTP_MAP_ALL(
        params.aligner,
        ch_reads,
        tuple([id:params.reference.split("/")[-1].split("\\.")[0]], params.reference) // channel: [ [id: filename], path(fasta) ]

    )
    ch_mapping = FASTP_MAP_ALL.out.ch_mapping
    ch_versions = ch_versions.mix(FASTP_MAP_ALL.out.versions.first())

    //
    // Primer clipping
    //
    // if (! params.skip_primer_clipping) {
    // BAM_CLIP_PRIMER_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(BAM_CLIP_PRIMER_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(BAM_CLIP_PRIMER_ALL.out.versions.first())
    // }

    //
    // Variant calling
    //
    // BAM_CALL_VARIANT_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(BAM_CALL_VARIANT_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(BAM_CALL_VARIANT_ALL.out.versions.first())

    //
    // Consensus calling
    //
    // VCF_CALL_CONSENSUS_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(VCF_CALL_CONSENSUS_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(VCF_CALL_CONSENSUS_ALL.out.versions.first())

    //
    // Genome QC
    //
    // FASTA_GENOME_QC_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(FASTA_GENOME_QC_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(FASTA_GENOME_QC_ALL.out.versions.first())

    //
    // Downstream analysis
    //
    // DOWNSTREAM_ANALYSIS_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(DOWNSTREAM_ANALYSIS_ALL.out.multiqc_files.collect{it[1]})
    // ch_versions = ch_versions.mix(DOWNSTREAM_ANALYSIS_ALL.out.versions.first())

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_pipeline_software_mqc_versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    if (!params.skip_multiqc) {
        ch_multiqc_config        = Channel.fromPath(
            "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
        ch_multiqc_custom_config = params.multiqc_config ?
            Channel.fromPath(params.multiqc_config, checkIfExists: true) :
            Channel.empty()
        ch_multiqc_logo          = params.multiqc_logo ?
            Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
            Channel.empty()

        summary_params      = paramsSummaryMap(
            workflow, parameters_schema: "nextflow_schema.json")
        ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))

        ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
            file(params.multiqc_methods_description, checkIfExists: true) :
            file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
        ch_methods_description                = Channel.value(
            methodsDescriptionText(ch_multiqc_custom_methods_description))

        ch_multiqc_files = ch_multiqc_files.mix(
            ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
        ch_multiqc_files = ch_multiqc_files.mix(
            ch_methods_description.collectFile(
                name: 'methods_description_mqc.yaml',
                sort: true
            )
        )


        // ch_multiqc_files.view()
        // ch_multiqc_config.view()
        // ch_multiqc_custom_config.view()
        // ch_multiqc_logo.view()
        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList()
        )
        multiqc_report = MULTIQC.out.report.toList()
    }
    emit:
    multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
