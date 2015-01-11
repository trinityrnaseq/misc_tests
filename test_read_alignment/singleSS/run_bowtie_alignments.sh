#!/bin/bash -ve

if [ -e top100k.Single.fq.gz ] && ! [ -e top100k.Single.fq ]
then
	gunzip -c top100k.Single.fq.gz > top100k.Single.fq
fi


if [ -e top100k.genome.gz ] && ! [ -e top100k.genome ]
then
	gunzip -c top100k.genome.gz > top100k.genome
fi


echo Demoing bowtie alignment pipeline

../../../trunk/util/bowtie_PE_separate_then_join.pl --single top100k.Single.fq \
	--seqType fq \
	--target top100k.genome \
	--aligner bowtie \
	--SS_lib_type F 









