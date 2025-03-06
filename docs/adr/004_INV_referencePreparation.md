## Title
Decision on how to handle IUPAC characters and N's in the reference sequence.

## Context
The INV GR workflow contains a process in which a python script is executed, which replaces all IUPAC characters and N's with static, unambiguous characters (ACGT).
Since this seems unintuitive and potentially could introduce differences in the results, we decided to assess the effects of these replacements.

Removing this step entirely resulted in problems with our variant caller lofreq, which produced VCF files with byte errors in them. This led to crashes in subsequent processes.
According to a comment in the original script, not only lofreq, but also bcftools consensus can't handle IUPAC characters.

Next, we assessed whether replacing IUPAC characters with statically defined bases introduces a downstream bias.
Therefore, we generated five distinct copies of the same reference genome where the IUPAC and 'N' characters were randomly replaced with unambiguous nucleotide characters. Each copy was used as a reference for genome reconstruction of three real data samples (5*3 experiments).
We observed changes in the VCF files due to different interpretations of the IUPAC characters. We noticed that especially N's are problematic, since these positions don't appear in the VCF files and seem to be conserved in the consensus sequence. However, in the case that an 'N' is replaced by an unambiguous nucleotide character, the position is considered for the variant calling. Subsequently, if the unambiguous nucleotide character in the reference genome differs from the majority allele among the aligned reads it will be replaced during the consensus generation. After removing the option of replacing IUPAC characters with N's, we observed identical md5sums of the consensus sequences across all runs for all samples respectively.

## Decision
We found that 'N's and IUPUC characters cause issues with internal software (lofreq).
However, replacing those characters with unambiguous nucleotide characters showed no downstream effect on the generated consensus sequences.
For the purpose of reproducibility, we decide to define static replacements of all IUPAC and 'N' characters into unambiguous nucleotide characters.

## Status
- [ ] proposed
- [x] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro:
  - no randomness, good reproducibility
  - both IUPAC and 'N' character positions in the reference genome are now considered for variant calling and consensus generation
- Con:
  - seems unintuitive and error-prone at first
  - an extremely high ratio of characters in the reference genome being replaced by the proposed method might causes alignment artifacts. However, within the scope of our assessment we observed this effect as minor/ not present.
