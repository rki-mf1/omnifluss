#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#author: Stephan Fuchs (Robert Koch Institute, MF-1, fuchss@rki.de),adapted by Dimitri Ternovoj (Robert Koch Institute, MF1)

import os
import argparse
import re
import sys
import vcf

def parse_args():
    parser = argparse.ArgumentParser(prog="adjust_dels", description="adjusts deletions in VCFs", )
    parser.add_argument('--name', help="sample name", type=str, required=True)
    parser.add_argument('--vcf', metavar="FILE", help="vcf file", type=str, required=True)
    return parser.parse_args()

# open file handles considering compression state
def process(sample_name, file):
    vcf_reader = vcf.Reader(filename=file)
    vcf_writer = vcf.Writer(open(f"{sample_name}.del_adjust.vcf", 'w'), vcf_reader)
    for record in vcf_reader:
         if len(record.REF) > len(record.ALT):
              vcf_writer.write_record(record)
         #if len(record.REF) != 1:
         #     record.ALT = ",".join([x + "?"*(len(record.REF)-len(x)) for x in record.ALT.split(",")])
         #vcf_writer.write_record(record)
def write_version():
    with open("version.tmp","w") as fw:
        fw.write("1.0.0")

def main():
    args = parse_args()
    process(args.name, args.vcf)
    write_version()
        

if __name__ == "__main__":
    main()