# Influenza

**Omnifluss** can perform genome reconstruction of Influenza viruses using Illumina short-read NGS data.

## Usage

Basic usage of omnifluss to reconstruct Influenza virus genomes from Illumina paired-end (PE) short-read data:
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity,INV_illumina \
    -input my_sample_sheet.csv \
    -outdir results
```

## Inputs

### Sample sheet

The sample sheet (.csv) provided via `--input` specifies the raw read sequence data files (.fastq) used by omnifluss.
For instance:

| sample     |          fastq_1                 |          fastq_2                 |
|------------|----------------------------------|----------------------------------|
|INV_ILL_NB1 | /path/to/experiment_NB1_R1.fastq | /path/to/experiment_NB1_R2.fastq |
|INV_ILL_NB2 | /path/to/experiment_NB2_R1.fastq | /path/to/experiment_NB2_R2.fastq |
|INV_ILL_NB3 | /path/to/experiment_NB3_R1.fastq | /path/to/experiment_NB3_R2.fastq |

### Segment database

WIP

### Kraken database

WIP

### Adapter file

WIP

## Parameters

Besides the very crucial parameters explained in [Inputs](#inputs), various parameters can be finetuned thoughout the workflow.

## Output

WIP