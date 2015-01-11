#!/bin/bash -ve

if [ -e top100k.Left.fq.gz ] && ! [ -e top100k.Left.fq ]
then
	gunzip -c top100k.Left.fq.gz > top100k.Left.fq
fi

if [ -e top100k.Right.fq.gz ] && ! [ -e top100k.Right.fq ]
then
	gunzip -c top100k.Right.fq.gz > top100k.Right.fq
fi



if [ -e top100k.genome.gz ] && ! [ -e top100k.genome ]
then
	gunzip -c top100k.genome.gz > top100k.genome
fi

echo Demoing BLAT alignment pipeline

../../../trunk/util/alignReads.pl --left top100k.Left.fq --right top100k.Right.fq\
	--seqType fq \
	--SS_lib_type RF \
	--target top100k.genome \
	--aligner BLAT -I 500









