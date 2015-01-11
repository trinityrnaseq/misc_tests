#!/bin/bash
## add to path

# for snigel
export PATH=${PATH}:/references/software/:/references/software/bowtie/:~/SVN/trinityrnaseq-code/trunk/trinity-plugins/parafly/bin/:~/SVN/ryggrad/:~/utilities/

./prepReads.pl  refSeqs.fa

./run_bowtie_align_reads_to_refSeq.pl  --threads 4 --target_list target_files.list

./runTrinity.pl  --threads 6 --target_list target_files.list 

./runAnanas.pl  --threads 6 --target_list ./target_files.list


../../../trunk/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target refSeqs.fa --query trin.fasta --min_per_id 99 --max_per_gap 1 --min_per_length 99

../../../trunk/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target refSeqs.fa --query ananas.fasta --min_per_id 99 --max_per_gap 1 --min_per_length 99




