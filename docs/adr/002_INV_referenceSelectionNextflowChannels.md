## Title
Design decisions about how to organize and pass information via Nextflow channels during the reference selection.

## Context
The INV GR workflow currently has two modes of reference selection, _static_ and _auto_.
However, in each mode the input to the workflow is given in a different format, a single FASTA file or a database of FASTA files, respectively.
Both modes must yield a channel of FASTA sequences for downstream steps of the main workflow.
In case of _auto_ mode index files might be present or absent.
Required is a Nextflow channel design with functional seperation such that, ideally, a minimal number of channels are passed and no channels need to be joint, split or reordered as part of the main workflow.

## Decision
The _static_ mode uses the single FASTA file to construct the final reference channel (ch_fasta_references) which is not subject to further selection steps.
The _auto_ mode uses one or multiple FASTA files, here called _database_, to construct a reference channel which is subsequently processed by the reference selection subworkflows.
Before the reference selection in _auto_ mode, a set of index files is created corresponding to each FASTA in the database if not present.
The index files for all FASTA files in the database are stored in a separate channel (ch_kma_index).

![ReferenceSelectionNextflowChannels](docs/images/ref_selection_channels.png)

## Status
- [x] proposed
- [ ] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro:
- - properly labeled and streamlined Nextlow channels
- - mode selection can be taken to the main workflow s.t. we avoid using and logging reference selection subworkflows in _static_ mode
- Con:
- - one more channel to pass between subworkflows in _auto_ mode compared to a joint channel of FASTA files plus their corresponding indexes
- - creation of _ch_fasta_references_ brings sightly more code to the main workflow _igsmp.nf_
