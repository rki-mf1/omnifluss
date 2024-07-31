#!/bin/bash
#Author: Dr Charles Foster http://github.com/charlesfoster
i_flag=''
g_flag=''
h_flag=''
o_flag=''

print_usage() {
	printf "Usage: bash add_fake_genotype.sh -i in.vcf.gz [-g genotype] -o out.vcf.gz\n"
	printf "Genotype defaults to 1 if not specified\n"
}

if [[ $# -eq 0 ]] ; then
	print_usage
    exit 1
fi

while getopts 'i:g:ho:' flag; do
  case "${flag}" in
		i) IN="${OPTARG}" ;;
		g) GENOTYPE="${OPTARG}" ;;
    h) print_usage
           exit 1 ;;
    o) OUT="${OPTARG}" ;;
    *) print_usage
       exit 1 ;;
  esac
done

if [ ! -f ${IN} ]; then
    printf "\nError: input file not found\n"
		print_usage
		exit 1
fi

if [ -z "${GENOTYPE}" ]
  then
    echo "No genotype specified: setting to 1"
		GENOTYPE=1
fi

NAME=$(basename ${IN} | cut -f1 -d ".")
gunzip -kc ${IN} | \
sed -e '6i##FORMAT=<ID=GT,Number=1,Type=String,Description="Genotype">' \
-e "s|FILTER\tINFO|FILTER\tINFO\tFORMAT\t${NAME}|g" | \
awk -F'\t' -v genotype=${GENOTYPE} -v OFS="\t" '/^[^#]/{ $9 = "GT"; $10 = genotype }1' | \
bgzip -c > ${OUT}
tabix -p vcf ${OUT}
#printf "VCF with fake genotype written to ${OUT}\n"

#save the version
echo "1.0.0" > version.tmp
exit 0