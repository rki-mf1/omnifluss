## Title
Design decision about how to organize and pass information via Nextflow channels during the reference selection.

## Context
The INV GR workflow currently has two modes of reference selection, _static_ and _auto_.
Both modes require a channel of valid FASTA files (ch_fasta_references).
A corresponding set of index files (ch_kma_index) is created if in _auto_ mode. 

## Decision
Present, the creation of the channel of valid FASTA files (ch_fasta_references) is done prior to any functional subworkflow involved in reference selection.
The creation of the channel for the index files (ch_kma_index) is done via a dedicated subworkflow.
The _ch_index_kma_ only exists in _auto_ mode.

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
- - more I/O channels to pass between subworkflows in _auto_ mode
- - creation of _ch_fasta_references_ brings sightly more code to the main workflow _igsmp.nf_
