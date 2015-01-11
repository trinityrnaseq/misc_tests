#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 known_counts.txt  RSEM.isoforms.results\n\n";

my $known_counts = $ARGV[0] or die $usage;
my $rsem_counts = $ARGV[1] or die $usage;


main: {
    my %known;
    {
        open (my $fh, $known_counts) or die "Error, cannot open file $known_counts";
        while (<$fh>) {
            chomp;
            my ($acc, $count) = split(/\t/);
            $known{$acc} = $count;
        }
        close $fh;
    }

    my %rsem;
    {
        open (my $fh, $rsem_counts) or die "Error, cannot open file $rsem_counts";
        while (<$fh>) {
            chomp;
            my @x = split(/\t/);
            my $acc = $x[0];
            my $count = $x[4];
            
            $rsem{$acc} = $count;
        }
        close $fh;
    }

    foreach my $acc (sort keys %known) {
        my $known_count = $known{$acc};
        my $rsem_count = $rsem{$acc};
        unless (defined $rsem_count) {
            $rsem_count = "NA";
        }

        print join("\t", $acc, $known_count, $rsem_count) . "\n";
    }

    exit(0);

}


        
        
