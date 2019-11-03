#!/bin/bash

set -e

scriptdir=`dirname $0`/..

## partition target reference transcripts
$scriptdir/partition_target_transcripts.pl  -R transcripts.fasta --by_Gene

find Seqs_dir/ -regex ".*refseqs.fa" | tee  targets.list

## simulate wgsim reads
$scriptdir/write_simulate_read_commands.pl  targets.list --wgsim --strand_specific --read_length 300 --frag_length 500 | tee sim_reads.wgsim.cmds

ParaFly -c sim_reads.wgsim.cmds -CPU 1


# run Trinity eval on wgsim reads
find Seqs_dir/ -regex ".*reads.wgsim_R300_F500_D200_SS.info" | tee wgsim.info_files

$scriptdir/info_files_to_eval_cmds.pl  wgsim.info_files testdir --strict --strand_specific | tee wgsim.info_files.eval_cmds

ParaFly -c wgsim.info_files.eval_cmds -CPU 1


