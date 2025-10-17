## Title
Filtering function excluding samples without reads after Kraken 2 classification or taxonomic read extraction

## Context
While running Omnifluss on routine runs, we observed errors that were caused by samples of bad quality (e.g. negative controls, samples with little INV content).
These samples could lead to errors in `KRAKENTOOLS_EXTRACTKRAKENREADS` or `KMA`, which is the subsequent process when the automatic reference selection is enabled.

To deal with this issue we implemented a filtering function that is once executed after `KRAKEN2_KRAKEN2` and once after `KRAKENTOOLS_EXTRACTKRAKENREADS` in the `FASTQ_TAXONOMIC_FILTERING_ALL` subworkflow.
For this function very specific decisions had to be made, which is the reason for this adr.
The most intuitive way of implementing such a function is to account for single-end and paired-end data and simply check the byte-size of the file(s) (e.g. `file(reads).size()` ).
However, this approach was not possible, because the read files are gzipped, which means that the file size can't be zero due to metadata that is stored in such files (even in empty ones).

The alternative to this was to not base the decision on size, but on number of lines, which is equal to zero in empty files. Since there is no native and suitable way to access gzipped files, we decided to use the 
countFastq operator, which counts the number of records in a channel of FastQ files. This operator has the downside that it is relatively slow and would do a lot of unnecessary work in our case, since all the reads would be counted,
although it would be sufficient to terminate after observing a single one.

With this in mind we implemented a pre-filter that is based on size. Instead of counting the reads for every file, only files smaller than a certain threshold (500 at the time of writing) are passed for read counting.
That way we can reduce the computational burden, while still be able to base the final decision on the number of reads.

While the essence of the function is covered, we observed a special case, which needed to be accounted for. We observed that our stub tests lead to EOF errors in the filtering function. 
These errors were caused by the countFastq operator, when applying it on files with byte-size zero. These files could only occur in stub tests, because "fake" gzipped files are created there.
These files have the same naming convention as gzipped files (`filename.gz`), but are simply generated with `touch filename.gz`, which leads to them having a byte-size of zero, although looking like gzipped files.
The solution for this problem was to explicitly check if a file has a byte-size of zero and only if it has not, to allow it for the checks described previously.

## Decision
We implemented a filtering function that is able to filter out empty FastQ files, using an approach with prefiltering based on the file size and the final decision based on number of lines.
We made sure that edgecases (stub-test) are covered and verified the correctness of the function by successfully rerunning samples that caused the errors in the first place.

## Status
- [ ] proposed
- [x] accepted
- [ ] deprecated
- [ ] superseded (via ADR#)

## Consequences
- Pro:
  - reliable filtering based on size and number of lines
  - efficient approach
- Con:
  - implementation not very intuitive without the information about the reasoning
  - specific check needed only for stub-tests
