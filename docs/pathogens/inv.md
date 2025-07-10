# Influenza

**Omnifluss** can perform genome reconstruction of Influenza viruses using Illumina short-read NGS data.

## Usage

Basic usage of omnifluss to reconstruct virus genomes:
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity \
    --input samplesheet.csv \
    --outdir results
```

This command launches a basic omnifluss run with samples from the _samplesheet_, tasks executed within _singularity_ containers, and results stored in an output folder called _results_.
We configured and optimised many settings and [Parameters](#parameters) to reconstruct Influenza virus genomes from Illumina paired-end (PE) short-read data.
These configurations can be trivially added to the basic omnifluss run via another profile:
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity,INV_illumina \
    --input samplesheet.csv \
    --outdir results
```

See the [Output](#output) chapter for the documentation of omnifluss' outputs.
Remember that the commands above use your last cached version (see [Updating the pipeline](#updating-the-pipeline)) of omnifluss.
If you like to run omnifluss at a specific release version, use the `-r` parameter of Naxtflow:
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity,INV_illumina \
    --input samplesheet.csv \
    --outdir results \
    -r v0.2.0
```

Further, you can resume an interrupted or broken pipeline runs via [resume](#resume).

### Updating the pipeline

When you run the commands above, Nextflow automatically pulls the pipeline code from GitHub and stores it as a cached version.
When running the pipeline, it will use a cached version by default if available - even if the pipeline has been updated on the developers' side.
To make sure that you're running the latest version of the omnifluss, you can manually update the cached version of the pipeline via
```bash
nextflow pull rki-mf1/omnifluss
```

Again, you can add `-r` for a specific version
```bash
nextflow pull -r v0.2.0 rki-mf1/omnifluss
```

### Reproducibility

To ensures that a specific version of the pipeline is used when running the pipeline, you can specify the pipeline version.
If you keep using the same tag, you'll be running the same version of the pipeline, even if there have been changes to the code afterwards.
You can visit the release page at [rki-mf1/omnifluss releases](https://github.com/rki-mf1/omnifluss/releases) and find the latest pipeline version at the top of the website.
When running the pipeline with `-r` (one hyphen), use eg. `-r v0.2.1`.
You can switch to another version any time by changing the vertion tag after the `-r` flag.
The version of the release will be written to the nextlow log for reproducibility.

## Inputs

### Sample sheet

The samples to be analysed are provided to omnifluss via a sample sheet (.csv) using the `--input` parameter.
It specifies the raw read sequence data files (.fastq) used by omnifluss.
For instance:

```csv
sample,fastq_1,fastq_2
INV_ILL_NB1,/path/to/experiment_NB1_R1.fastq.gz,/path/to/experiment_NB1_R2.fastq.gz
INV_ILL_NB2,/path/to/experiment_NB2_R1.fastq.gz,/path/to/experiment_NB2_R2.fastq.gz
INV_ILL_NB3,/path/to/experiment_NB3_R1.fastq.gz,/path/to/experiment_NB3_R2.fastq.gz
```

which refers to the structured information

| sample     |          fastq_1                    |          fastq_2                    |
|------------|-------------------------------------|-------------------------------------|
|INV_ILL_NB1 | /path/to/experiment_NB1_R1.fastq.gz | /path/to/experiment_NB1_R2.fastq.gz |
|INV_ILL_NB2 | /path/to/experiment_NB2_R1.fastq.gz | /path/to/experiment_NB2_R2.fastq.gz |
|INV_ILL_NB3 | /path/to/experiment_NB3_R1.fastq.gz | /path/to/experiment_NB3_R2.fastq.gz |

The argument parser will auto-detect the sample and paired-end information provided by the samples sheet.
Technically, the sample sheet can have as many columns as desired, however, only the first three columns are required and have to match the definition table below.

| Column | Description |
| ------ | ----------- |
| `sample`  | Custom sample name. This entry might be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |
| `fastq_2` | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                             |

### Segment database

\<WIP\>

### Kraken database

\<WIP\>

### Adapter file

You can especify a plain FASTA file for adapter clipping.
E.g. for _Illumina Nextera Transposase adapter_
```
>Illumina Nextera Transposase adapter fwd
TCGTCGGCAGCGTCAGATGTGTATAAGAGACAG
>Illumina Nextera Transposase adapter rev
GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG
```

## Parameters

> ***Note:***
> The documentation of pipeline parameters is generated automatically from the pipeline schema. Options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

Besides the very crucial parameters explained in [Inputs](#inputs), various parameters can be finetuned thoughout the workflow.
You can find the full list of parameters via `nextflow run rki-mf1/omnifluss -r <release-tag> --help`.
In order to not bloat the omnifluss run command and save time when typing the run for repeatedly you can provide pipeline parameters in `JSON` or `YAML` format via `-params-file <file>`.

> ***Warning:***
> Do not use the `-c <file>` to specify pipeline parameters as this will result to errors!
> Custom config files specified in `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) or module arguments (args).

For instance, the basic use case of omnifluss above can be specified with a params-file in yaml format:

```bash
nextflow run rki-mf1/omnifluss -profile singularity -params-file params.yaml
```

with:

```yaml
input: 'samplesheet.csv'
outdir: 'results'
```

### `resume`

Specify _-resume_ when restarting a pipeline.
Nextflow will use cached results from any pipeline steps where the inputs are the same, continuing from where it got to previously.
For input to be considered the same, not only the names must be identical but the files' contents as well.
For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`.
Use the `nextflow log` command to show previous run names.

## Output

After a successful run, the pipeline creates the following files and folders in your working directory:

```bash
work                # Directory containing the Nextflow working files
<outdir>            # Results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
```

\<WIP\>
