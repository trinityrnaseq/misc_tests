#!/bin/bash

if [ -e SP2.rnaseq.counts.matrix.gz ] && [ ! -e SP2.rnaseq.counts.matrix ]; then
    gunzip -c SP2.rnaseq.counts.matrix.gz > SP2.rnaseq.counts.matrix
fi

if [ -e Trinity.fasta.gz ] && [ ! -e Trinity.fasta ]; then
    gunzip -c Trinity.fasta.gz > Trinity.fasta
fi


## note, this is a bogus data set in this context - need to find a better example.


../../../trunk/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix SP2.rnaseq.counts.matrix --method DESeq --samples_file samples_described.txt 

