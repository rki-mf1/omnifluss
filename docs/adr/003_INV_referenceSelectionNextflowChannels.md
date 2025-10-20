## Title
Design decisions about the reference selection and how to load, organize, and pass reference sequences via Nextflow channels.

## Context
The Influenza workflow currently has two modes of providing reference genome segments via `--reference selection`, _static_ and _kma_.
For downstream processes of the workflow, both modes must eventually create and pass a channel of one final FASTA file of genome segments.

**Problem.** Each mode of the `--reference_selection` accepts a different input format: with _static_ the workflow takes a single FASTA file (with one sequence per segment) and with _kma_ the workflow takes a directory of multiple FASTA files (one file per segment containing one or more sequences) and their KMA index files, together called _database_.
These input formats require a Nextflow channel design where, ideally, a minimal number of channels are passed downstream and no channels need to be joint, split or reordered as part of the main workflow.

## Decision
We maintain a single global Nextflow channel `ch_final_topRefs` for the purpose of reference selection.
The _static_ mode simply passes a single FASTA file to `ch_final_topRefs` which is not subject to further selection steps.
The _kma_ mode uses the database to load its FASTA files and index files into two separate temporary channels.
These two channels are passed to the reference selection subworkflow `FASTA_REFERENCE_SELECTION_ALL`.
The reference selection subworkflow returns a single FASTA file of one sequence per segment.
This file is then stored in the `ch_final_topRefs` channel and passed to subsequent subworkflows.

⚠️ The automatic database indexing is work in progress and not implemented yet! ⤵️
![ReferenceSelectionNextflowChannels](docs/images/ref_selection_channels.png)

## Status
- [x] proposed
- [ ] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro:
- - properly labeled and single global Nextlow channel
- - _static_ mode skips entire reference selection procedure
- Con:
- - mildly more code in the main workflow due to the `--reference_selection` switch
