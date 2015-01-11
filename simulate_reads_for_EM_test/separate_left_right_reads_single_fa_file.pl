#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;

my $usage = "usage: $0 reads.fa\n\n";

my $reads_file = $ARGV[0] or die $usage;

main: {

    open (my $left_ofh, ">left.reads.fa") or die $!;
    open (my $right_ofh, ">right.reads.fa") or die $!;


    my $fasta_reader = new Fasta_reader($reads_file);
    
    while (my $seq_obj = $fasta_reader->next()) {

        my $acc = $seq_obj->get_accession();
        my $sequence = $seq_obj->get_sequence();

        if ($acc =~ m|/1$|) {
            print $left_ofh ">$acc\n$sequence\n";
        }
        elsif ($acc =~ m|/2$|) {
            print $right_ofh ">$acc\n$sequence\n";
        }
    }


    close $left_ofh;
    close $right_ofh;
    

    exit(0);

}

