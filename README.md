[![GitHub Release](https://img.shields.io/github/v/release/rki-mf1/omnifluss)](https://github.com/rki-mf1/omnifluss/releases)
[![Static Badge](https://img.shields.io/badge/Documentation%20-%20website%20-%20brightgreen?logo=Github%20Pages&link=https%3A%2F%2Frki-mf1.github.io%2Fomnifluss%2F)](https://rki-mf1.github.io/omnifluss/)
![GitHub Actions Workflow Status](https://img.shields.io/github/actions/workflow/status/rki-mf1/omnifluss/nf-test.yml?branch=dev&logo=githubactions&label=tests%20(%40dev))
![GitHub commit activity](https://img.shields.io/github/commit-activity/y/rki-mf1/omnifluss?logo=Github)


# rki-mf1/omnifluss

## Introduction

**rki-mf1/omnifluss** is a bioinformatics pipeline for the reconstruction of virus genomes.

Omnifluss takes raw sequencing data and performs operations such as quality filtering, primer clipping, taxanomic classification, alignment, variant calling, consensus assembly, and optionally reference selection.
The specific algorithms and software selected for these operations primarily depend on two parameters: virus type and sequencing technology.
Beside these two parameters many settings and subroutines can be finetuned.
After a successful run `omnifluss` returns a consensus sequence, intermediate files, and an HTML report that includes statistics of the individual operations.

## Usage

Please visit our **[omnifluss website](https://rki-mf1.github.io/omnifluss/)** for our full documentation.

<details><summary> TL;DR (setup environment) </summary>

You need Nextflow and at least one package manager (conda) or container engine (singularity, docker) available.
You can install Nextflow via conda:
```bash
conda create -n omnifluss -c bioconda -c conda-forge nextflow==25.04.3
conda activate omnifluss
```
</details>

<details><summary> TL;DR (run) </summary>

```bash
nextflow run rki-mf1/omnifluss \
   -profile <docker/singularity/.../institute/virus> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```
</details>

## Credits

rki-mf1/omnifluss was originally written by the RKI MF1 Viroinf team.

## Funding

This project was supported by co-funding from the European Union’s EU4Health programme under project no. 101113012 (IMS-HERA2).

## Citations

\<WIP\>

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.
