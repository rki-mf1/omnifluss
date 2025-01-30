/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQ_QC_TRIMMING_ALL               } from '../subworkflows/local/fastq_qc_trimming_all'
include { FASTQ_TAXONOMIC_FILTERING_ALL       } from '../subworkflows/local/fastq_taxonomic_filtering_all'
include { FASTA_PROCESS_REFERENCE_ALL         } from '../subworkflows/local/fasta_process_reference_all'
include { FASTQ_MAP_ALL                       } from '../subworkflows/local/fastq_map_all'
include { BAM_CALL_VARIANT_ALL                } from '../subworkflows/local/bam_call_variant_all'
include { BAM_SPECIAL_VARIANTS_CASE_ALL       } from '../subworkflows/local/bam_special_variants_case_all'
include { VCF_CALL_CONSENSUS_ALL              } from '../subworkflows/local/vcf_call_consensus_all'
include { MULTIQC                             } from '../modules/nf-core/multiqc/main'

include { paramsSummaryMap                    } from 'plugin/nf-validation'
include { paramsSummaryMultiqc                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML              } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText              } from '../subworkflows/local/utils_nfcore_igsmp_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow IGSMP {

    take:
    ch_samplesheet                       // channel: [ meta, fastq ]

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
            ch_reads,
            params.fastp_adapter_fasta ? file(params.fastp_adapter_fasta, checkIfExists:true) : []
        )
        .trimmed_reads
        | set {ch_reads}

        ch_multiqc_files = ch_multiqc_files.mix(FASTQ_QC_TRIMMING_ALL.out.multiqc_files.collect())
        ch_versions = ch_versions.mix(FASTQ_QC_TRIMMING_ALL.out.versions)
    }

    //
    // Taxonomic classification
    //
    if (! params.skip_taxonomic_filtering) {
        FASTQ_TAXONOMIC_FILTERING_ALL(
            params.taxonomic_classifier,                // string
            ch_reads,                                   // channel: [ val(meta), fastq ]
            params.kraken2_db,                          // string
            params.kraken2_taxid_filter_list            // string
        )
        .extracted_kraken2_reads
        | set {ch_reads}

        ch_multiqc_files  = ch_multiqc_files.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.multiqc_files.collect())
        ch_versions       = ch_versions.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.versions)
    }

    //
    // Reference selection
    //
    // FASTA_SELECT_REFERENCE_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(FASTA_SELECT_REFERENCE_ALL.out.multiqc_files.collect())
    // ch_versions = ch_versions.mix(FASTA_SELECT_REFERENCE_ALL.out.versions)

    //
    // Reference processing
    //
    FASTA_PROCESS_REFERENCE_ALL(
        params.reference_processing,
        params.aligner,
        ref = tuple([id:file(params.fasta).getBaseName()], params.fasta) //TODO: Adapted to output from fasta_select_reference_all
    )
    ch_ref = FASTA_PROCESS_REFERENCE_ALL.out.preped_ref
    ch_fai_index = FASTA_PROCESS_REFERENCE_ALL.out.fai_index
    ch_bwa_index = FASTA_PROCESS_REFERENCE_ALL.out.bwa_index
    ch_versions = ch_versions.mix(FASTA_PROCESS_REFERENCE_ALL.out.versions)

    //
    // Mapping
    //
    FASTQ_MAP_ALL(
        params.aligner,                                                               // string
        ch_reads,                                                                     // channel: [ val(meta), fastq ]
        ch_ref,                                                                       // channel: [ val(meta), fasta ]
        ch_bwa_index                                                                  // channel: [ val(meta), index ]
    )
    ch_mapping = FASTQ_MAP_ALL.out.bam
    ch_mapping_index = FASTQ_MAP_ALL.out.bai
    ch_versions = ch_versions.mix(FASTQ_MAP_ALL.out.versions)
    // ch_multiqc_files mark duplicates, samtools stats?

    //
    // Primer clipping // thinking of moving this FASTQ_MAP_ALL (or adding an now subwf), as it's a post-mapping step like picard_remove_duplicates
    //
    // if (! params.skip_primer_clipping) {
    // BAM_CLIP_PRIMER_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(BAM_CLIP_PRIMER_ALL.out.multiqc_files.collect())
    // ch_versions = ch_versions.mix(BAM_CLIP_PRIMER_ALL.out.versions)
    // }

    //
    // Variant calling
    //
    BAM_CALL_VARIANT_ALL(
        params.variant_caller,
        ch_mapping,
        ch_ref,
        ch_fai_index
    )
    ch_vcf           = BAM_CALL_VARIANT_ALL.out.vcf
    ch_versions      = ch_versions.mix(BAM_CALL_VARIANT_ALL.out.versions)

    //
    // Special INV variant calling
    //
    ch_rescued_variants = Channel.empty()
    if (workflow.profile.contains("INV")) {
        BAM_SPECIAL_VARIANTS_CASE_ALL(
            ch_mapping,
            ch_mapping_index,
            ch_ref,
            ch_fai_index
        )
        ch_rescued_variants = BAM_SPECIAL_VARIANTS_CASE_ALL.out.bed
    }

    //
    // Consensus calling
    //
    VCF_CALL_CONSENSUS_ALL(
        params.consensus_caller,
        params.consensus_mincov,
        ch_ref,                             // channel: [ val(meta), fasta ]
        BAM_CALL_VARIANT_ALL.out.vcf,       // channel: [ val(meta), vcf   ]
        BAM_CALL_VARIANT_ALL.out.bam,       // channel: [ val(meta), bam   ]
        ch_rescued_variants                 // channel: [ val(meta), bed   ]
    )

    ch_versions = ch_versions.mix(VCF_CALL_CONSENSUS_ALL.out.versions)
    // ch_multiqc_files = ch_multiqc_files.mix(VCF_CALL_CONSENSUS_ALL.out.multiqc_files.collect())


    //
    // Genome QC
    //
    // FASTA_GENOME_QC_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(FASTA_GENOME_QC_ALL.out.multiqc_files.collect())
    // ch_versions = ch_versions.mix(FASTA_GENOME_QC_ALL.out.versions)

    //
    // Downstream analysis
    //
    // DOWNSTREAM_ANALYSIS_ALL(
    //
    // )
    // ch_multiqc_files = ch_multiqc_files.mix(DOWNSTREAM_ANALYSIS_ALL.out.multiqc_files.collect())
    // ch_versions = ch_versions.mix(DOWNSTREAM_ANALYSIS_ALL.out.versions)

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
