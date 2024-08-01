#!/usr/bin/env python
# [Author]  T Krannich   (Maintainer)
# [Author]  K Winter     (Implemented the original R script)
# [Info]    Get variants with good qualities that failed the variant filtering due to the lofreq strand bias filter.

import sys
import os
import gzip

inVCF   = sys.argv[1]
basename = os.path.basename(inVCF)
file_name = basename.split('.', 1)[0]
file_extension = basename[len(file_name):]

QUAL    = -1
FILTER  = -1
INFO    = -1

hq_lines = list()

# Iterate over the VCF file and find all variants matching the rescue criteria
with gzip.open(inVCF, 'rt') as file:
    for line in file:
        # skip header
        if line.startswith('##'):
            continue

        # VCF sanity check
        if line.startswith('#CHROM'):
            h_line = line.strip().split('\t')
            assert(h_line[1] == 'POS')
            assert(h_line[5] == 'QUAL')
            assert(h_line[6] == 'FILTER')
            assert(h_line[7] == 'INFO')
            QUAL, FILTER, INFO = 5, 6, 7

        # get relevant lines
        else:
            if (float(line.split('\t')[QUAL]) > 9999) and (line.split('\t')[FILTER] != 'PASS'):
                hq_lines.append(line)


# Write BED file
# If there are no entries to rescue, write an empty BED file
if not hq_lines:
    with open(file_name + '.special_case_variant_mask.bed', 'w'):
        pass
# If there are variants to be rescued
else:
    with open(file_name + '.special_case_variant_mask.bed', 'w') as ofile:
        for hq_line in hq_lines:
            hq_line_list = hq_line.strip().split('\t')

            # check AF threshold
            info_fields = hq_line_list[INFO].split(';')
            assert(info_fields[1].startswith('AF='))
            af = float(info_fields[1][3:])
            if af < 0.9:
                continue
            
            var_name    = hq_line_list[0]
            # Start is POS - 1 for VCF to BED file index shift
            start_pos   = str(int(hq_line_list[1]) - 1)
            end_pos     = hq_line_list[1]   # WARNING:  I took this definition of "end_pos" over from the original script.
                                            #           In my assumption this only works for SNVs but not for indels.
                                            #           But at this point I also don't know how the BED is used afterwards.

            ofile.write(var_name + "\t" + start_pos + "\t" + end_pos + "\n")




