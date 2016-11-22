#!/usr/bin/env perl

use strict;
use warnings;


my $usage = "usage: $0 fileA.fasta fileB.fasta\n\n";

my $fileA_fasta = $ARGV[0] or die $usage;
my $fileB_fasta = $ARGV[1] or die $usage;


main: {

    my %cluster_to_asmbl_count_A = &parse_cluster_counts($fileA_fasta);

    my %cluster_to_asmbl_count_B = &parse_cluster_counts($fileB_fasta);

    my %clusters = map { + $_ => 1 } (keys %cluster_to_asmbl_count_A, keys %cluster_to_asmbl_count_B);

    foreach my $cluster (sort keys %clusters) {
        
        my $countA = $cluster_to_asmbl_count_A{$cluster} || 0;
        my $countB = $cluster_to_asmbl_count_B{$cluster} || 0;

        print join("\t", $cluster, $countA, $countB) . "\n";
    }

    exit(0);
    
}



####
sub parse_cluster_counts {
    my ($file) = @_;

    my %cluster_to_counts;

    open(my $fh, $file) or die "Error, cannot open file $file";
    while (<$fh>) {
        if (/^>(\S+)/) {
            my $acc = $1;

            my @pts = split(/_/, $acc);
            
            my $cluster = $pts[1];
            
            $cluster_to_counts{$cluster}++;

        }
    }
    close $fh;

    return(%cluster_to_counts);

}
            
