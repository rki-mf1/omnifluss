#!/usr/bin/env python3
# -*- coding: utf-8 -*-
#author:		Stephan Fuchs (Robert Koch Institute, MF1)
#maintainer:	Dimitri Ternovoj (Robert Koch Institute, MF1)
#maintainer:	Thomas Krannich (Robert Koch Institute, MF1)

import os
import sys
import argparse
import textwrap
import gzip
from Bio import SeqIO

def parse_args():
	parser = argparse.ArgumentParser(prog="prep_reference.py", description="writes a dna-safe fasta file", )
	parser.add_argument('-f', '--fasta', metavar='FASTA_FILE', help="fasta file to check", type=str, required=True)
	parser.add_argument('-o', '--out', metavar='FASTA_FILE', help="dna-safe fasta file to write (exisiting file will be overwritten!)", type=str, required=True)
	parser.add_argument('-l', '--len', metavar='INT', help="sequence line length (set 0 to avoid new lines, default=60)", type=int, default=60)
	return parser.parse_args()

def is_gzipped(file_path):
    """Check if a file is GZipped by reading its first two bytes."""
    with open(file_path, "rb") as f:
        return f.read(2) == b'\x1f\x8b'  # initial bytes for Gzip

def prepare_reference(fasta,length,out):
	valid_letters = "ATGCURYSWKMBDHVN.-"

	#check file
	if not os.path.isfile(fasta):
		sys.exit("error: the input fasta file does not exist")

	"""Read a FASTA file, handling both plain text and GZipped formats."""
	open_func = gzip.open if is_gzipped(fasta) else open
	mode = "rt"  # Read as text

	# process file
	with open(out, "w") as out_handle:
		with open_func(fasta, mode) as in_handle:
			for record in SeqIO.parse(in_handle, "fasta"):
				header = str(record.description)
				#print(header)
				#remove colon and spaces in header for subsequent tools to work
				header = header.replace(":", "_").replace(" ", "_").replace("(", "_").replace(")", "_").replace("'", "_").replace(".", "_").replace("[", "_").replace("]", "_")
				seq = str(record.seq).upper()
				if not all(i in valid_letters for i in seq):
					sys.exit("error: sequence '" + header + "' in " + fasta + " contains non-IUPAC characters.")
				#replace any non standard characters - otherwise problems with lofreq and bcltools consensus
				seq = seq.replace(".", "").replace("-", "").replace("U", "T").replace("W", "A").replace("S", "C").replace("M", "A").replace("K", "G").replace("R", "A").replace("Y", "C").replace("B", "C").replace("D", "A").replace("H", "A").replace("V", "A").replace("N", "A")
				if length > 0:
					seq = textwrap.fill(seq, width=length)
					#print(seq)
				out_handle.write(">" + header + "\n" + seq + "\n")

def write_version():
    with open("version.tmp","w") as fw:
        fw.write("1.0.0")
		
def main():
    args = parse_args()
    prepare_reference(args.fasta,args.len,args.out+"_preped.fasta")
    write_version()

if __name__ == "__main__":
	main()