#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Nuc_translator;

my $usage = "usage: $0 kmers.fasta\n\n";

my $kmers_file = $ARGV[0] or die $usage;

main: {

    open (my $fh, $kmers_file) or die $!;
    while (<$fh>) {
        
        if (/^>/) {
            print;
        }
        else {
            chomp;
            my $kmer = $_;

            if (rand(2) >= 1) {
                $kmer = &reverse_complement($kmer);
            }
            print "$kmer\n";
        }
    }

    close $fh;
    
    exit(0);
    
}


       
