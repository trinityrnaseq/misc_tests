#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 known_counts results.xprs\n\n";

my $known_counts = $ARGV[0] or die $usage;
my $eXpress_counts = $ARGV[1] or die $usage;


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
    
    my %eXpress_est;
    my %eXpress_eff;
    {
        open (my $fh, $eXpress_counts) or die "Error, cannot open file $eXpress_counts";
        while (<$fh>) {
            chomp;
            my @x = split(/\t/);
            my $acc = $x[1];
            my $est_count = $x[6];
            my $eff_count = $x[7];
            $eXpress_est{$acc} = $est_count;
            $eXpress_eff{$acc} = $eff_count;
        }
        close $fh;
    }
    
    foreach my $acc (sort keys %known) {
        my $known_count = $known{$acc};
        my $est_count = $eXpress_est{$acc};
        my $eff_count = $eXpress_eff{$acc};
        unless (defined $est_count) {
            $est_count = "NA";
        }
        unless (defined $eff_count) {
            $eff_count = "NA";
        }
        
        print join("\t", $acc, $known_count, $est_count, $eff_count) . "\n";
    }
    
    exit(0);

}


        
        
