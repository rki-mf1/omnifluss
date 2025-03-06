## Title
Decision on how to handle IUPAC characters and N's in the reference sequence.

## Context
The INV GR workflow contains a process in which a python script is executed, which replaces all IUPAC characters and N's with static, unambiguous characters (ACGT).
Since this seems unintuitive and potentially could introduce differences in the results, we decided to assess the effects of these replacements.

Removing this step entirely resulted in problems with our variant caller lofreq, which produced VCF files with byte errors in them. This led to crashes in subsequent processes.
According to a comment in the original script, not only lofreq, but also bcftools consensus can't handle IUPAC characters.

Next we accessed whether we introduce some bias when replacing characters with static bases.
For this we randomized the replacement and ran 5 runs with different seeds for our 3 internal samples.
We observed changes in the VCF files due to different interpretations of the IUPAC characters. We noticed that especially N's are problematic, since these positions don't appear in the VCF files and seem to be conserved in the consensus sequence. In cases however where a nucleotide is chosen, it appears in the VCF files and can later be corrected by the reads that map at that position for the consensus sequence. After removing the option of replacing IUPAC characters with N's, we observed identical md5sums of the consensus sequences across all runs for all samples respectively.

## Decision
We found out that N's and IUPAC characters are problematic, but once they are replaced by nucleotides, these can be corrected throughout the workflow.
For reproducibility purposes we therefore decided to replace all IUPAC characters and N's with static nucleotides.

## Status
- [x] proposed
- [ ] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro:
- - no randomness, good reproducibility
- - positions have the chance to be corrected and to appear in the consensus sequence
- Con:
- - seems unintuitive and error-prone at first
