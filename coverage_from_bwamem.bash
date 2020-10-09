#!/bin/bash

#calculate coverage with bwa mem, samtools, bedtools and python script
show_help() {
cat << EOF
Usage: ${0##*/} 

Process:
        baw index to build the index
	bwa mem to align the reads
	gunzip the sam files
	samtools view transform sam to bam
	samtools sort bam
	bedtools genomecov calculate depth
	python3 script to get coverage
	
Example usage: 
	bash coverage_from_bwamem.bash -g genome.fa -r reads.fa -t 20 -o ./ -p chen

NOTICE: 
	Make sure only fasta format are supported here
        !!!!YOU ARE ENCOVERAGED TO USE FULL PATH !!!!
	
EOF
}
while getopts "g:r:t:o:p:h" opt; do
	case "$opt" in
		h | --help)
			show_help
			exit 0
			;;
		g | --genome)
			Input_genome=$OPTARG
			;;
		r | --reads)
			Input_reads=$OPTARG
			;;
		t | --threads)
			N_threads=$OPTARG
			;;
		o | --outdir)
			Out_dir=$OPTARG
			;;
		p | --prefix)
			P_Prefix=$OPTARG
			;;
		\?)
			echo "Invalid option: -$OPTARG" >&2
			;;
		'?')
			show_help >&2
			exit 1
			;;
		-?*)
			print 'Warning: Unknown option (ignored) : %s\n' "$1" >&2
			;;
		:)
			echo "Option -$OPTARG requires an argument." >&2
			exit 1
			;;
		*) # default case: if no more options then break out of the loop
			break
	esac

done
if [ -z "$Input_genome" ]
then
	echo "No input fasta, -f must be specified"
	exit
fi

echo "inputfile  = $Input_genome"
echo "inputreads = $Input_reads"
echo "outdir     = $Out_dir"
echo "threads    = $N_threads"
echo "prefix     = $P_Prefix"

#genome_dirname=dirname $Input_genome
#genome_basename=basename $Input_genome
#find $genome_dirname -name '$genome_basename.ann'

########################################
#############bwa index build############
########################################
echo "
-----------------------------------starting build bwa index--------------------------------------------
"

if [ -e ${Input_genome}.ann ]
#    find $genome_dirname -name '$genome_basename.ann'
then
    echo "
                                YOU HAVE ALREADY BUILT THE INDEX
    "
else
    echo "
                      NONE INDEX EXIST, WILL BUILD INDEX WITH BWA INDEX
    "
	bwa index $Input_genome
fi
echo "
--------------------------------------bwa index finish-------------------------------------------------
"
########################################
###########bwa mem and sam2bam##########
########################################
echo "
-----------------------------------starting bwa mem align----------------------------------------------
"

bwa mem -t $N_threads $Input_genome $Input_reads | gzip -3 > ${Out_dir}/${P_Prefix}.sam.gz
gunzip -k ${Out_dir}/${P_Prefix}.sam.gz
samtools view -bS ${Out_dir}/${P_Prefix}.sam > ${Out_dir}/${P_Prefix}.bam
samtools sort -@ $N_threads ${Out_dir}/${P_Prefix}.bam -o ${Out_dir}/${P_Prefix}_sort.bam

echo "
-----------------------------------bwa mem align finished----------------------------------------------
"
########################################
##########bedtools to coverage##########
########################################
echo "
---------------------------------------calculate coverage----------------------------------------------
"
bedtools genomecov -ibam ${Out_dir}/${P_Prefix}_sort.bam > ${Out_dir}/${P_Prefix}.genomecov.txt
python3 ~/scripts/calculate-contig-coverage.py ${Out_dir}/${P_Prefix}.genomecov.txt

rm ${Out_dir}/${P_Prefix}.sam
rm ${Out_dir}/${P_Prefix}.bam

echo "
------------------------------------calculate coverage finish------------------------------------------
"





