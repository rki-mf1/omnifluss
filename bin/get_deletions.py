#!/usr/bin/env python3
# -*- coding: utf-8 -*-
# author: Stephan Fuchs (Robert Koch Institute, MF-1, fuchss@rki.de),adapted by Dimitri Ternovoj (Robert Koch Institute, MF1)

import argparse
import vcf


def parse_args():
    parser = argparse.ArgumentParser(
        prog="get_deletions.py",
        description="extract deletions from VCFs",
    )
    parser.add_argument(
        "--vcf", metavar="FILE", help="vcf file", type=str, required=True
    )
    parser.add_argument(
        "--out", metavar="FILE", help="output vcf file", type=str, required=True
    )
    parser.add_argument("--version", action="version", version="%(prog)s 1.0.1")
    return parser.parse_args()


# open file handles considering compression state
def process(file, out):
    vcf_reader = vcf.Reader(filename=file)
    vcf_writer = vcf.Writer(open(f"{out}", "w"), vcf_reader)
    for record in vcf_reader:
        if len(record.REF) > len(record.ALT):
            vcf_writer.write_record(record)
        # if len(record.REF) != 1:
        #     record.ALT = ",".join([x + "?"*(len(record.REF)-len(x)) for x in record.ALT.split(",")])
        # vcf_writer.write_record(record)


def main():
    args = parse_args()
    process(args.vcf, args.out)


if __name__ == "__main__":
    main()
