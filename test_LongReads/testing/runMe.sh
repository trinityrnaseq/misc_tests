#!/bin/bash

set -e


## partition target reference transcripts
../partition_target_transcripts.pl  -R transcripts.fasta

find Seqs_dir/ -regex ".*refseqs.fa" | tee  targets.list


## simulate reads via home-grown method
../write_simulate_read_commands.pl  targets.list  | tee sim_reads.cmds

ParaFly -c sim_reads.cmds -CPU 1


## simulate wgsim reads
../write_simulate_read_commands.pl  targets.list --wgsim --strand_specific | tee sim_reads.wgsim.cmds

ParaFly -c sim_reads.wgsim.cmds -CPU 1


# run Trinity eval on wgsim reads
find Seqs_dir/ -regex ".*reads.wgsim_R76_F300_D200_FR.info" | tee wgsim.info_files

../info_files_to_eval_cmds.pl  wgsim.info_files testdir --strict --strand_specific | tee wgsim.info_files.eval_cmds

ParaFly -c wgsim.info_files.eval_cmds -CPU 1


