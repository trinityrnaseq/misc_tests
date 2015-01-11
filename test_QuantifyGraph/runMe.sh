#!/bin/bash -v

if [ -e comp1.raw.graph.gz ] && ! [ -e comp1.raw.graph ]; then
    gunzip -c comp1.raw.graph.gz > comp1.raw.graph
fi


if [ -e comp1.raw.fasta.gz ] && ! [ -e comp1.raw.fasta ]; then
    gunzip -c comp1.raw.fasta.gz > comp1.raw.fasta
fi


../../trunk/Chrysalis/QuantifyGraph -g comp1.raw.graph -i comp1.raw.fasta -strand -o ladeda.out -no_cleanup
