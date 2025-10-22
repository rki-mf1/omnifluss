#!/usr/bin/env python3
import os
import argparse
import re

def parse_args():
    parser = argparse.ArgumentParser(
        prog="generate_sample_sheet.py",
        description="writes a sample sheet that can be used for omnifluss downstream",
    )
    
    parser.add_argument(
    "--input",
    help="ids corresponding to the fasta files",
    type=str,
    required=True,
    )
    
    parser.add_argument(
    "-o",
    "--outdir",
    help="output directory used in the Nextflow run",
    type=str,
    required=True,
    )
    
    parser.add_argument(
    "-pd",
    "--project_dir",
    help="project directory used in the Nextflow run",
    type=str,
    required=True,
    )
    
    parser.add_argument("-v", "--version", action="version", version="%(prog)s 1.0.0")
    return parser.parse_args()

def write_sample_sheet(ids, fastas):
    assert len(ids) == len(fastas)
    
    with open("omnifluss_sample_sheet.csv","w") as fw:
        fw.write("sample,fasta\n")
        for i in range(len(ids)):
            fw.write(f"{ids[i]},{fastas[i]}\n")


def main():
    args = parse_args()
    
    #prep input
    ids = []
    fastas = []
    
    #form the correct path, depending on whether an absolute or relative outdir was supplied
    path = args.outdir if args.outdir.startswith("/") else os.path.join(args.project_dir,args.outdir)  
    
    for elem in args.input.split(","):
        
        #extract and generate paths to fastas
        if elem.endswith(".fa") or elem.endswith(".fa]"):
            elem = elem.rstrip("]")
            fastas.append(os.path.join(path,elem.split("/")[-1]))
            
        #extract ids
        else:
            match = re.search(r'id:([^\s\]]+)', elem)
            
            if match:
                ids.append(match.group(1))

    write_sample_sheet(ids, fastas)


if __name__ == "__main__":
    main()
