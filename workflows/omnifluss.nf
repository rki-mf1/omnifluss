/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQ_QC_TRIMMING_ALL               } from '../subworkflows/local/fastq_qc_trimming_all'
include { FASTQ_TAXONOMIC_FILTERING_ALL       } from '../subworkflows/local/fastq_taxonomic_filtering_all'
include { FASTA_REFERENCE_SELECTION_ALL       } from '../subworkflows/local/fasta_reference_selection_all/main.nf'
include { FASTA_PROCESS_REFERENCE_ALL         } from '../subworkflows/local/fasta_process_reference_all'
include { FASTQ_MAP_ALL                       } from '../subworkflows/local/fastq_map_all'
include { BAM_GENOMECOV_ALL                   } from '../subworkflows/local/bam_genomecov_all'
include { BAM_CALL_VARIANT_ALL                } from '../subworkflows/local/bam_call_variant_all'
include { BAM_SPECIAL_VARIANTS_CASE_ALL       } from '../subworkflows/local/bam_special_variants_case_all'
include { BAM_SAMTOOLS_STATS_ALL              } from '../subworkflows/local/bam_samtools_stats_all'
include { VCF_CALL_CONSENSUS_ALL              } from '../subworkflows/local/vcf_call_consensus_all'
include { INV_REPORTING_ALL                   } from '../subworkflows/local/inv_reporting_all'
include { MULTIQC                             } from '../modules/nf-core/multiqc/main'

include { paramsSummaryMap                    } from 'plugin/nf-schema'
include { paramsSummaryMultiqc                } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML              } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText              } from '../subworkflows/local/utils_nfcore_omnifluss_pipeline'


/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow OMNIFLUSS {

    take:
    ch_samplesheet                       // channel: [ meta, fastq ]

    main:
    ch_reads                    = ch_samplesheet
    ch_versions                 = Channel.empty()
    ch_multiqc_files            = Channel.empty()
    ch_final_topRefs            = Channel.empty()
    ch_fastp_jsons              = Channel.empty() //from here: channels for reporting
    ch_kraken_reports           = Channel.empty()
    ch_kma_mapping_refs         = Channel.empty()
    ch_markduplicates_metrics   = Channel.empty()
    ch_bedtools_genomecov       = Channel.empty()
    ch_samtools_coverage        = Channel.empty()
    ch_samtools_flagstat        = Channel.empty()
    ch_consensus_calls          = Channel.empty()
    ch_report                   = Channel.empty()

    //
    // Parameters' sanity check for those and their combinations that cannot be verified via nf-schema@2.3.0
    //
    if (params.reference_selection == "kma" && (params.reference != null || params.reference_selection_db == null)){
        exit 1, "When selecting 'kma' as 'reference_selection' parameter, 'reference_selection_db' must be specified, 'reference' should not be specified."
    }
    else if (params.reference_selection == "static" && (params.reference == null || params.reference_selection_db != null)){
        exit 1, "When selecting 'static' as 'reference_selection' parameter, 'reference' must be specified, 'reference_selection_db' should not be specified."
    }

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

        ch_fastp_jsons = FASTQ_QC_TRIMMING_ALL.out.fastp_jsons.collect{it[1]} //prepared for reporting
        ch_multiqc_files    = ch_multiqc_files.mix(FASTQ_QC_TRIMMING_ALL.out.multiqc_files.collect())
        ch_versions         = ch_versions.mix(FASTQ_QC_TRIMMING_ALL.out.versions)
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

        ch_kraken_reports = FASTQ_TAXONOMIC_FILTERING_ALL.out.kraken2_report.collect{it[1]} //prepared for reporting
        ch_multiqc_files  = ch_multiqc_files.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.multiqc_files.collect())
        ch_versions       = ch_versions.mix(FASTQ_TAXONOMIC_FILTERING_ALL.out.versions)
    }

    //
    // Reference selection
    //
    if (params.reference_selection == "static"){

        ch_final_topRefs = ch_reads.map { meta, _reads -> [meta, params.reference]}
    }
    else {
        ch_reference_db_fastas = Channel.fromPath("${params.reference_selection_db}/*.fasta")
            .map{fasta ->
                def id = fasta.getName().tokenize('.')[0]
                return tuple([id: id], fasta)
            }

        ch_reference_db_index = Channel.fromPath("${params.reference_selection_db}/*.{length.b,seq.b,comp.b,name}")
            .map{indexfile ->
                def id = indexfile.getName().tokenize('.')[0]
                return [id, indexfile]
            }
            .groupTuple()
            .map{
                id, files ->
                return [[id:id], files]
            }

        FASTA_REFERENCE_SELECTION_ALL(
            params.reference_selection,
            ch_reads,
            ch_reference_db_fastas,
            ch_reference_db_index
        )
        ch_kma_mapping_refs = FASTA_REFERENCE_SELECTION_ALL.out.spa.collect{it[1]} //prepared for reporting
        ch_final_topRefs    = FASTA_REFERENCE_SELECTION_ALL.out.final_topRefs
        ch_versions         = ch_versions.mix(FASTA_REFERENCE_SELECTION_ALL.out.versions)
        // ch_multiqc_files = ch_multiqc_files.mix(FASTA_SELECT_REFERENCE_ALL.out.multiqc_files.collect())
    }

    //
    // Reference processing
    //
    FASTA_PROCESS_REFERENCE_ALL(
        params.reference_processing,
        params.aligner,
        ch_final_topRefs
    )
    ch_ref          = FASTA_PROCESS_REFERENCE_ALL.out.preped_ref
    ch_ref_index    = FASTA_PROCESS_REFERENCE_ALL.out.fai_index
    ch_bwa_index    = FASTA_PROCESS_REFERENCE_ALL.out.bwa_index
    ch_versions     = ch_versions.mix(FASTA_PROCESS_REFERENCE_ALL.out.versions)

    //
    // Mapping
    //
    FASTQ_MAP_ALL(
        params.aligner,  // string
        ch_reads,        // channel: [ val(meta), fastq ]
        ch_bwa_index,    // channel: [ val(meta), bwa_index ]
        ch_ref,          // channel: [ val(meta), fasta ]
        ch_ref_index     // channel: [ val(meta), fai_index ]
    )
    ch_mapping                = FASTQ_MAP_ALL.out.bam
    ch_mapping_index          = FASTQ_MAP_ALL.out.bai
    ch_markduplicates_metrics = FASTQ_MAP_ALL.out.markduplicates_metrics.collect{it[1]} //prepared for reporting
    ch_versions               = ch_versions.mix(FASTQ_MAP_ALL.out.versions)
    ch_multiqc_files          = ch_multiqc_files.mix(FASTQ_MAP_ALL.out.multiqc_files)

    //
    // Collecting Data for Report (1/2)
    //
    if (! params.skip_report) {
        BAM_GENOMECOV_ALL(
            ch_mapping,
            [],
            "coverage.tsv",
            true
        )
        ch_bedtools_genomecov = BAM_GENOMECOV_ALL.out.bedtools_cov.collect{it[1]}
    }
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
        ch_ref_index
    )
    ch_vcf           = BAM_CALL_VARIANT_ALL.out.vcf     // should be used for consensus subworkflow
    ch_bam           = BAM_CALL_VARIANT_ALL.out.bam     // should be used for consensus subworkflow
    ch_versions      = ch_versions.mix(BAM_CALL_VARIANT_ALL.out.versions)

    //
    // Collecting Data for Report (2/2)
    //
    if (! params.skip_report) {
        BAM_SAMTOOLS_STATS_ALL(
            ch_bam,
            ch_ref,
            ch_ref_index
        )
        ch_samtools_coverage = BAM_SAMTOOLS_STATS_ALL.out.samtools_cov.collect{it[1]}
        ch_samtools_flagstat = BAM_SAMTOOLS_STATS_ALL.out.samtools_flagstat.collect{it[1]}
        ch_multiqc_files     = ch_multiqc_files.mix(BAM_SAMTOOLS_STATS_ALL.out.multiqc_files)
    }

    //
    // Special INV variant calling
    //
    ch_rescued_variants = Channel.empty()
    if (workflow.profile.contains("INV")) {
        BAM_SPECIAL_VARIANTS_CASE_ALL(
            ch_mapping,
            ch_mapping_index,
            ch_ref,
            ch_ref_index
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
        ch_vcf,                             // channel: [ val(meta), vcf   ]
        ch_bam,                             // channel: [ val(meta), bam   ]
        ch_rescued_variants                 // channel: [ val(meta), bed   ]
    )
    ch_consensus_calls = VCF_CALL_CONSENSUS_ALL.out.consensus_calls.collect{it[1]}
    ch_versions = ch_versions.mix(VCF_CALL_CONSENSUS_ALL.out.versions)

    if (! params.skip_report) {
        //collect files for report
        ch_fastp_jsons = ch_fastp_jsons.ifEmpty([])
        ch_kraken_reports = ch_kraken_reports.ifEmpty([])
        ch_kma_mapping_refs = ch_kma_mapping_refs.ifEmpty([])
        ch_markduplicates_metrics = ch_markduplicates_metrics.ifEmpty([])
        ch_bedtools_genomecov = ch_bedtools_genomecov.ifEmpty([])
        ch_samtools_coverage = ch_samtools_coverage.ifEmpty([])
        ch_samtools_flagstat = ch_samtools_flagstat.ifEmpty([])
        ch_consensus_calls = ch_consensus_calls.ifEmpty([])

        //warning if all input channels for the Omnifluss Report are empty
        if (ch_fastp_jsons == [] && ch_kraken_reports == [] && ch_kma_mapping_refs == [] && ch_markduplicates_metrics == [] && ch_bedtools_genomecov == [] && ch_samtools_coverage == [] && ch_samtools_flagstat == [] && ch_consensus_calls == []){
            log.warn "Input for the Omnifluss Report is empty"
        }
        //
        // Reporting
        //
        INV_REPORTING_ALL(
            params.reporting_script,
            ch_fastp_jsons,
            ch_kraken_reports,
            ch_kma_mapping_refs,
            ch_markduplicates_metrics,
            ch_bedtools_genomecov,
            ch_samtools_coverage,
            ch_samtools_flagstat,
            ch_consensus_calls,
            params.outdir
        )
        ch_report = INV_REPORTING_ALL.out.report
        ch_versions = ch_versions.mix(INV_REPORTING_ALL.out.versions)
    }

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
            name:  'omnifluss_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    //
    // MODULE: MultiQC
    //
    ch_multiqc_report = Channel.empty()
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
        ch_multiqc_files = ch_multiqc_files.mix(
            ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
        ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
            file(params.multiqc_methods_description, checkIfExists: true) :
            file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
        ch_methods_description                = Channel.value(
            methodsDescriptionText(ch_multiqc_custom_methods_description))

        ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
        ch_multiqc_files = ch_multiqc_files.mix(
            ch_methods_description.collectFile(
                name: 'methods_description_mqc.yaml',
                sort: true
            )
        )

        MULTIQC (
            ch_multiqc_files.collect(),
            ch_multiqc_config.toList(),
            ch_multiqc_custom_config.toList(),
            ch_multiqc_logo.toList(),
            [],
            []
        )
        ch_multiqc_report = MULTIQC.out.report.toList()
    }
    emit:
    multiqc_report = ch_multiqc_report           // channel: /path/to/multiqc_report.html
    report         = ch_report                   // channel: /path/to/qc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
