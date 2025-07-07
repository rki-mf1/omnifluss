//
// Alignment with BWA
//

include { BWA_MEM                 } from '../../../modules/nf-core/bwa/mem/main'
include { BAM_SORT_STATS_SAMTOOLS } from '../bam_sort_stats_samtools/main'

workflow FASTQ_ALIGN_BWA {
    take:
    ch_reads        // channel (mandatory): [ val(meta), [ path(reads) ] ]
    ch_index        // channel (mandatory): [ val(meta2), path(index) ]
    val_sort_bam    // boolean (mandatory): true or false
    ch_fasta        // channel (optional) : [ val(meta3), path(fasta) ]

    main:
    ch_versions = Channel.empty()

    //sort channels to maintain order across different channels
    ch_reads_cpy = ch_reads.map { meta, reads -> return [meta.id, meta, reads]}
    ch_fasta_cpy = ch_fasta.map { meta, fasta -> return [meta.id, meta, fasta]}
    ch_index_cpy = ch_index.map { meta, index -> return [meta.id, meta, index]}

    ch_bwa_mem_input = ch_reads_cpy.join(ch_fasta_cpy).join(ch_index_cpy)
        .multiMap{_sample_id, meta, reads, meta2, reference, meta3, bwa_index ->
            ch_reads: [ meta, reads ]
            ch_ref: [ meta2, reference ]
            ch_bwa_index: [ meta3, bwa_index ]
        }

    //
    // Map reads with BWA
    //
    BWA_MEM(
        ch_bwa_mem_input.ch_reads,
        ch_bwa_mem_input.ch_bwa_index,
        ch_bwa_mem_input.ch_ref,
        val_sort_bam
    )
    ch_versions = ch_versions.mix(BWA_MEM.out.versions.first())

    BAM_SORT_STATS_SAMTOOLS(
        BWA_MEM.out.bam,
        ch_fasta
    )
    ch_versions = ch_versions.mix(BAM_SORT_STATS_SAMTOOLS.out.versions)

    emit:
    bam_orig = BWA_MEM.out.bam                      // channel: [ val(meta), path(bam) ]

    bam      = BAM_SORT_STATS_SAMTOOLS.out.bam      // channel: [ val(meta), path(bam) ]
    bai      = BAM_SORT_STATS_SAMTOOLS.out.bai      // channel: [ val(meta), path(bai) ]
    csi      = BAM_SORT_STATS_SAMTOOLS.out.csi      // channel: [ val(meta), path(csi) ]
    stats    = BAM_SORT_STATS_SAMTOOLS.out.stats    // channel: [ val(meta), path(stats) ]
    flagstat = BAM_SORT_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), path(flagstat) ]
    idxstats = BAM_SORT_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), path(idxstats) ]

    versions = ch_versions                          // channel: [ path(versions.yml) ]
}
