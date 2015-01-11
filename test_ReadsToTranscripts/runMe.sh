#!/bin/bash

if [ -e both.fa.gz ] && [ ! -e both.fa ]; then
    gunzip -c both.fa.gz > both.fa
fi

if [ -e chrysalis/bundled.fasta.gz ] && [ ! -e chrysalis/bundled.fasta ]; then
    gunzip -c chrysalis/bundled.fasta.gz > chrysalis/bundled.fasta
fi


../../trunk/Chrysalis/ReadsToTranscripts -i both.fa -f chrysalis/bundled.fasta -o chrysalis -strand -max_mem_reads 5000 -verbose

exit $?
