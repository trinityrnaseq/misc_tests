#!/bin/bash

../partition_target_transcripts.pl  -R transcripts.fasta

find Seqs_dir/ -regex ".*refseqs.fa" | tee  targets.list

../write_simulate_read_commands.pl  targets.list  | tee sim_reads.cmds

ParaFly -c sim_reads.cmds -CPU 1

../write_simulate_read_commands.pl  targets.list --wgsim --strand_specific | tee sim_reads.wgsim.cmds

ParaFly -c sim_reads.wgsim.cmds -CPU 1
