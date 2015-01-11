#!/bin/bash

if [ -e simul.transcriptome.cdnas.gz ] && [ ! -e simul.transcriptome.cdnas ]; then
    gunzip -c simul.transcriptome.cdnas.gz > simul.transcriptome.cdnas 
fi

if [ ! -e results.xprs ]; then
    express simul.transcriptome.cdnas simul.transcriptome.sam.nameSorted.bam
fi

../join_known_vs_eXpress_computed_counts.pl known_expr_vals.txt results.xprs > results.xprs.wKnown

R --vanilla -q < ../plot_eXpress_vs_known.R
