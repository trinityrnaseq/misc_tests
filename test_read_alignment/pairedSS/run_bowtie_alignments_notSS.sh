#!/bin/bash -ve

if [ -e top100k.Left.fq.gz ] && ! [ -e top100k.Left.fq ]
then
	gunzip -c top100k.Left.fq.gz > top100k.Left.fq
fi

if [ -e top100k.Right.fq.gz ] && ! [ -e top100k.Right.fq ]
then
	gunzip -c top100k.Right.fq.gz > top100k.Right.fq
fi



if [ -e top100k.genes.cds.gz ] && ! [ -e top100k.genes.cds ]
then
	gunzip -c top100k.genes.cds.gz > top100k.genes.cds
fi

echo Demoing bowtie alignment pipeline

../../../trunk/util/bowtie_PE_separate_then_join.pl  --left top100k.Left.fq --right top100k.Right.fq\
	--seqType fq --run_rsem \
	--target top100k.genes.cds \
	--aligner bowtie 









