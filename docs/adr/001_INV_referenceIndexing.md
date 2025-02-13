## Title
Design decision about when to perform reference indexing at INV GR.

## Context
The INV GR workflow requires a KMA index to be present at time of invocation of the reference selection.

## Decision
Present, the check for existence and creation of the KMA index is excluded from the reference selection subworkflow.
Generating the KMA index will be subject to another separate subworkflow.

## Status
- [ ] proposed
- [x] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro: avoids race condition during the reference selection for each sample
- Con: Might violates the the nf-core standard (format recommendation) in case the subworkflow will only contain one process, i.e. the indexing
