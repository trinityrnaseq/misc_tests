#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;

my $usage = "usage: $0 file.fasta\n\n";

my $fasta_file = $ARGV[0] or die $usage;

main: {

    my %kmers;

    my $fasta_reader = new Fasta_reader($fasta_file);
    
    while (my $seq_obj = $fasta_reader->next()) {
        my $sequence = $seq_obj->get_sequence();

        for (my $i = 0; $i <= length($sequence) - 25; $i++) {

            my $kmer = substr($sequence, $i, 25);

            $kmers{$kmer}++;

        }
    }
    
    foreach my $kmer (keys %kmers) {
        print ">2\n$kmer\n";
    }

    exit(0);
}



