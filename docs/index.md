[![GitHub Release](https://img.shields.io/github/v/release/rki-mf1/omnifluss)](https://github.com/rki-mf1/omnifluss/releases)
![Static Badge](https://img.shields.io/badge/Nextflow-%E2%89%A524.04.2-darkgreen?logo=nextflow&label=Nextflow)
![Static Badge](https://img.shields.io/badge/nf--core-%E2%89%A53.3.1-darkgreen?logo=nf-core)
![Static Badge](https://img.shields.io/badge/nf--test-%E2%89%A50.9.2-darkgreen)
![Static Badge](https://img.shields.io/badge/run_with-conda-3EB049?logo=anaconda&labelColor=black)
![Static Badge](https://img.shields.io/badge/run_with-docker-0db7ed?logo=docker&labelColor=black)
![Static Badge](https://img.shields.io/badge/run_with-singularity-1d355c?labelColor=black)


# Omnifluss

**rki-mf1/omnifluss** is a bioinformatics pipeline for the reconstruction of virus genomes.

Omnifluss takes raw sequencing data and performs operations such as quality filtering, primer clipping, taxanomic classification, alignment, variant calling, consensus assembly, and optionally reference selection.
The specific algorithms and software selected for these operations primarily depend on two parameters: virus type and sequencing technology.
Beside these two parameters many settings and subroutines can be finetuned.
After a successful run `omnifluss` returns a consensus sequence, intermediate files, and an HTML report that includes statistics of the individual operations.


### Technical prerequisites

For system requirements of omnifluss please see the [Prerequisites](prerequisites.md) page.


<hr>

*Last update: July, 15th 2025*
