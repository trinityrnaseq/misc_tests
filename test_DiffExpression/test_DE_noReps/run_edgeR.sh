#!/bin/bash

if [ -e SP2.rnaseq.counts.matrix.gz ] && [ ! -e SP2.rnaseq.counts.matrix ]; then
    gunzip -c SP2.rnaseq.counts.matrix.gz > SP2.rnaseq.counts.matrix
fi

if [ -e Trinity.fasta.gz ] && [ ! -e Trinity.fasta ]; then
    gunzip -c Trinity.fasta.gz > Trinity.fasta
fi

../../../trunk/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix SP2.rnaseq.counts.matrix --method edgeR
