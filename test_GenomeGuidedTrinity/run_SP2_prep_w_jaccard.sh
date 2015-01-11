#!/bin/bash -ve


if [ -e SP2.chr.fa.gz ] && [ ! -e SP2.chr.fa ]; then
    gunzip -c SP2.chr.fa.gz > SP2.chr.fa
fi

if [ -e SP2.annot.bed.gz ] && [ ! -e SP2.annot.bed ]; then
    gunzip -c SP2.annot.bed.gz > SP2.annot.bed
fi

if [ -e SP2.chr.bam ] && [ ! -e SP2.chr.sam ]; then
    samtools view SP2.chr.bam > SP2.chr.sam
fi


../../trunk/util/prep_rnaseq_alignments_for_genome_assisted_assembly.pl --coord_sorted_SAM SP2.chr.sam -I 100000 --SS_lib_type RF 

find Dir_SP2.* -regex ".*reads" > read_files.list

../../trunk/util/GG_write_trinity_cmds.pl --reads_list_file read_files.list --paired --SS --jaccard_clip > trinity_GG.cmds

../../trunk/Inchworm/bin/ParaFly -c trinity_GG.cmds -CPU 2 -vv


## execute the trinity commands, and then pull together the aggregate fasta file like so:

find Dir_SP2*  -name "*inity.fasta" -exec cat {} + | ../../trunk/util/inchworm_accession_incrementer.pl > allTrin.fa

# which will ensure that each trinity accession is unqiue.


echo done.

