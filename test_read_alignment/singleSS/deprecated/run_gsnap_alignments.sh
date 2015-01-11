#!/bin/bash -ve

if [ -e top100k.Single.fq.gz ] && ! [ -e top100k.Single.fq ]
then
	gunzip -c top100k.Single.fq.gz > top100k.Single.fq
fi


if [ -e top100k.genome.gz ] && ! [ -e top100k.genome ]
then
	gunzip -c top100k.genome.gz > top100k.genome
fi


echo Demoing bwa alignment pipeline

../../../trunk/util/alignReads.pl --single top100k.Single.fq \
	--seqType fq \
	--SS_lib_type F \
	--target top100k.genome \
	--aligner gsnap









