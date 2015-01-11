#!/bin/bash -ve

if [ -e simul.transcriptome.cdnas.gz ] && [ ! -e simul.transcriptome.cdnas ]; then
    gunzip -c simul.transcriptome.cdnas.gz > simul.transcriptome.cdnas 
fi


../../../trunk/util/RSEM_util/run_RSEM_align_n_estimate.pl --transcripts simul.transcriptome.cdnas --seqType fa --left left.reads.fa --right right.reads.fa --no_group_by_component

../join_known_vs_computed_counts.pl known_expr_vals.txt RSEM.isoforms.results > compare.txt

R --vanilla -q < ../plot_rsem_vs_known.R


