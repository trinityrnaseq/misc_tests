#!/bin/bash -ve




../../trunk/Trinity.pl --seqType fq --left left.fastq.gz --right right.fastq.gz --JM 1G --bfly_opts "--dont-collapse-snps --min_per_id_same_path=100 --max_diffs_same_path=0 --max_internal_gap_same_path=0"


