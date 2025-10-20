# Influenza

**Omnifluss** can perform genome reconstruction of Influenza viruses using Illumina short-read NGS data.

## Usage

Here, we begin the explanations of how to run omnifluss with basic examples and progress to more advanced setups.
Omnifluss can be finetuned in many aspects such as runtime [parameters](#parameters), internal algorithms, deactivation of subroutines, optimisation to certain compute environments and usage of different databases. <br>

### Basic run

To begin with, a command for a basic run of omnifluss is
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity \
    --input samplesheet.csv \
    --reference my_virus_reference.fasta \
    --kraken2_db /path/to/my/kraken2db/ \
    --outdir results
```
> ***Note:***
> Mind the usage of different hyphen here! We use a single hyphen for Nextflow options and use a double hyphen for omnifluss specific parameters.

This command launches a basic omnifluss run with tasks executed within singularity containers, sequence data defined in the [samplesheet](#sample-sheet), a FASTA file containing a reference sequence, a [Kraken2](https://ccb.jhu.edu/software/kraken2/) database, and results stored in an output folder called _results_.
See the [Output](#output) chapter for the documentation of omnifluss' outputs.

### Reproducibility

To ensures that a specific version of omnifluss is used when running the pipeline, you can specify a release tag.
If you keep using the same release tag, you'll be running the same version of omnifluss, even if there have been changes to the code since that version.
You can visit the [releases page](https://github.com/rki-mf1/omnifluss/releases) and find the latest pipeline version at the top of the website.
Then, by running omnifluss with the Nextflow option `-r` (using one hyphen, eg. `-r v0.2.1`), you can switch to a particular version of omnifluss:
```bash
nextflow run rki-mf1/omnifluss \
    -r v0.2.1 \
    -profile singularity \
    --input samplesheet.csv \
    --reference my_virus_reference.fasta \
    --kraken2_db /path/to/my/kraken2db/ \
    --outdir results
```
The version of omnifluss used in a particular run is written to the Nextlow log file for reproducibility.

### Updating the pipeline

When you run omnifluss as in the [basic run](#basic-run) example, Nextflow automatically pulls the pipeline code from the GitHub repository and stores a local copy (called _cached_ version).
When running the pipeline again, Nextflow uses this cached version by default if available - even if the pipeline code has been updated since the initial copying.
You can manually update the cached version of the pipeline to the latest available version via
```bash
nextflow pull rki-mf1/omnifluss
```

Again, you can also add `-r` to update the cached version to a specific release via
```bash
nextflow pull -r v0.2.0 rki-mf1/omnifluss
```

### Configs and profiles

Omnifluss provides a plethora of parameters (use `--help` to inspect the manual page) to configure the workflow.
To process Illumina paired-end short-read sequencing data of Influenza virus samples, we have prepared a [configuration file](https://github.com/rki-mf1/omnifluss/blob/update_website/conf/pathogens/INV_illumina.config) with best-practise settings.
This predefined configuration file can be provided to an omnifluss run via the `-profile` option:
```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity,INV_illumina \
    --input samplesheet.csv \
    --reference my_virus_reference.fasta \
    --kraken2_db /path/to/my/kraken2db/ \
    --outdir results
```
Using the `INV_illumina` profile will overwrite multiple default parameters of omnifluss.
Please inspect the configuration file for more details about the Influenza virus-specific parameters.
Note that you can still provide omnifluss parameters on the command line in addition to profiles.
The [pipeline parameter precedence](https://www.nextflow.io/docs/latest/cli.html#pipeline-parameters) in Nextflow prioritizes command line parameters over parameters specified in a configuration file.
See `-params-file` for more details on custom configuration files.

## Parameters

### `--input`

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

| sample      | fastq_1                             | fastq_2                             |
| ----------- | ----------------------------------- | ----------------------------------- |
| INV_ILL_NB1 | /path/to/experiment_NB1_R1.fastq.gz | /path/to/experiment_NB1_R2.fastq.gz |
| INV_ILL_NB2 | /path/to/experiment_NB2_R1.fastq.gz | /path/to/experiment_NB2_R2.fastq.gz |
| INV_ILL_NB3 | /path/to/experiment_NB3_R1.fastq.gz | /path/to/experiment_NB3_R2.fastq.gz |

The argument parser will automatically detect the sample and paired-end information provided by the sample sheet.
The sample sheet requires a three-column entry per sample which has to match the definition below.

| Column    | Description                                                                                                                                                                             |
| --------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `sample`  | Custom sample name. This entry might be identical for multiple sequencing libraries/runs from the same sample. Spaces in sample names are automatically converted to underscores (`_`). |
| `fastq_1` | Full path to FastQ file for Illumina short reads 1. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                              |
| `fastq_2` | Full path to FastQ file for Illumina short reads 2. File has to be gzipped and have the extension ".fastq.gz" or ".fq.gz".                                                              |

### `--reference`

File containing one or multiple reference sequence.
Parameter value is a FASTA file.
For the influenza virus, the FASTA file typically contains eight reference sequences, i.e. one per segment.
However, another collection might suits your reearch question.
All reads from the `--input` FASTQ files are mapped against the sequences in `--reference` and these mappings will ultimately be used for a reference-guided assembly.

Exactly one of the two parameters `--reference` and `--reference_selection_db` has to be provided to omnifluss when process Influenza virus data.
These two parameters provide the references for the consensus sequence reconstruction.
Depending on the choice of the first reference parameter, the `--reference_selection` parameter has to be set accordingly.
The parameter combination `--reference_selection kma --reference_selection_db <path>` (default when using the `INV_illumina` profile) activates a selection process for the best fitting reference from the given reference database at `<path>`.
Please see `--reference_selection_db` for more details on the reference database.
The parameter combination `--reference_selection static --reference <fasta>` takes strictly the sequences in `<fasta>` as reference sequences for the genome reconstruction.

### `--reference_selection`

Reference selection mode.
Choice of "_kma_" and "_static_".
Please see `--reference` for more details.

### `--reference_selection_db`

Database for automatic reference selection.
Parameter value is a _path_ to a reference database.
The reference database has to comply with the following format: for each of the genome segments of the Influenza virus (HA, NA, MP, NP, NS, PA, PB1, PB2), the reference database can contain up to one FASTA file containing one or multiple reference sequences.
Further, the FASTA file names have to begin with `<segment_name>.`, i.e. a valid database could looks like
```bash
/path/
├── HA.segment.fasta
├── MP.segment.fasta
├── NA.segment.fasta
├── NP.segment.fasta
├── NS.segment.fasta
├── PA.segment.fasta
├── PB1.segment.fasta
└── PB2.segment.fasta
``` 
Please see `--reference` for more details.

### `--kraken2_db`

\<WIP\>

### `--fastp_adapter_fasta`

You can especify a plain FASTA file for adapter clipping.
E.g. for _Illumina Nextera Transposase adapter_

```
>Illumina Nextera Transposase adapter fwd
TCGTCGGCAGCGTCAGATGTGTATAAGAGACAG
>Illumina Nextera Transposase adapter rev
GTCTCGTGGGCTCGGAGATGTGTATAAGAGACAG
```

### `--help`

Various parameters can be finetuned throughout the workflow.
You can find the full list of parameters via `nextflow run rki-mf1/omnifluss -r <release-tag> --help`.

> **_Note:_**
> The documentation of pipeline parameters is generated automatically from the pipeline schema. Options are part of Nextflow and use a _single_ hyphen (pipeline parameters use a double-hyphen).

### `-params-file`

Each parameter of omnifluss can also be written into a configuration file (in JSON or YAML format) and provided to omnifluss via `-params-file <file>`.
For instance, the [basic run](#basic-run) case of omnifluss can be shortened and specified with a configuration file:

```bash
nextflow run rki-mf1/omnifluss \
    -profile singularity \
    -params-file params.yaml
```

with the corresponding YAML file `params.yaml`:

```yaml
input: 'samplesheet.csv'
reference: 'my_virus_reference.fasta'
kraken2_db: '/path/to/my/kraken2db/'
outdir: 'results'
```

> ***Warning:***
> Do not use the `-c <file>` to specify pipeline parameters as this will result in errors!
> Custom config files specified in `-c` must only be used for [tuning process resource specifications](https://nf-co.re/docs/usage/configuration#tuning-workflow-resources) or module arguments (args).

### `-resume`

Specify _-resume_ when restarting a pipeline.
Nextflow reuses all cached intermediate results from pipeline steps start are not affected by changes between the runs.
For more info about this parameter, see [this blog post](https://www.nextflow.io/blog/2019/demystifying-nextflow-resume.html).

You can also supply a run name to resume a specific run: `-resume [run-name]`.
Use the `nextflow log` command to show previous run names.

### `--outdir`

\<WIP\>

## Output

After a successful run, the pipeline creates the following files and folders in your working directory:

```bash
work                # Directory containing the Nextflow working files
<outdir>            # Results in specified location (defined with --outdir)
.nextflow_log       # Log file from Nextflow
```

\<WIP\>
