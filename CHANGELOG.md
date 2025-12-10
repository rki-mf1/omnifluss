# rki-mf1/omnifluss: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## Unreleased

## 0.4.0 - [2025-12-09]

### `Updated`

- nf-core tools/template version `3.4.1`
- include nf-core configs template part
- minimum Nextflow version `25.04.0`

### `Added`
  
- added output samplesheet for clade assignment using rki-mf1/omnifluss_downstream

## 0.3.0 - [2025-09-19]

### `Added`

- added `no_intermediate_files` parameter (boolean), specifying whether to publish intermediate files or not
- added two read qc plots to the report
- added display of samples that dropped throughout the workflow

### `Fixed`

- fixed input parameter validation
- restructured inputs for reporting
- implemented a check for kraken2 related parameters if selected

## 0.2.1 - [2025-08-27]

### `Added`

- fixed filtering function to correctly exclude files without reads after Kraken 2 classification or taxonomic read extraction

## 0.2.0 - [2025-08-15]

### `Added`

- added report for Influenza
- added CI tests and GitHub Actions
  - copied from pipeline template, because they were not included with the template update
  - implemented different test
    - full pipeline with INV ENA data, stub tests
    - first tests local modules & subwfs
- added docs website

### `Fixed`

- restrictions for input reference parameters
- krakentools parameter to not include potential tax parents
- updated `CITATIONS.md`
- fixed empty read file handling before and after `KRAKENTOOLS_EXTRACTKRAKENREADS`
- fixed weird signaling error with `grep` replaced with `gawk`
- small output structure adjustments
- fixed module versions test; now robust w.r.t. module order and include path

### `Dependencies`

- update to nf-core pipeline template 3.3.1

## 0.1.0 - [2025-05-26]

### `Added`

- analysis tailored to Influenza short-read data (Illumina) based on Flupipe
  - updated automatic reference selection with `KMA`, instead of `minimap2`

## v1.0dev - [date]

Initial release of rki-mf1/omnifluss, created with the [nf-core](https://nf-co.re/) template.
