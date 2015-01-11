#!/bin/bash -ve

if [ -e mm9chr17.fasta.gz ] && [ ! -e mm9chr17.fasta ]; then
    gunzip -c mm9chr17.fasta.gz > mm9chr17.fasta
fi

if [ -e mm9chr17.annotation.bed.gz ] && [ ! -e mm9chr17.annotation.bed ]; then
    gunzip -c mm9chr17.annotation.bed.gz > mm9chr17.annotation.bed
fi

if [ -e mm9chr17.tophat.bam ] && [ ! -e mm9chr17.tophat.sam ]; then
    samtools view mm9chr17.tophat.bam > mm9chr17.tophat.sam
fi

#../../trunk/util/prep_rnaseq_alignments_for_genome_assisted_assembly.pl --coord_sorted_SAM tophat.sam -J 100000 -I 100000 --SS_lib_type RF --jaccard_clip

../../trunk/util/prep_rnaseq_alignments_for_genome_assisted_assembly.pl --coord_sorted_SAM mm9chr17.tophat.sam -I 100000 --SS_lib_type RF 

find Dir_tophat.sam.* -regex ".*reads" > read_files.list

../../trunk/util/GG_write_trinity_cmds.pl --reads_list_file read_files.list --paired --SS  > trinity_GG.cmds

## execute the trinity commands, and then pull together the aggregate fasta file like so:
#       find . -regex ".*inity.fasta" -exec cat {} \; | ../../trunk/util/inchworm_accession_incrementer.pl > allTrin.fa
# which will ensure that each trinity accession is unqiue.

