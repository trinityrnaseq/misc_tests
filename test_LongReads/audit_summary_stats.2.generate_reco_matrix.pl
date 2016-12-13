#!/usr/bin/env perl

use strict;
use warnings;

my @ranges = (50, 75, 100, 150); # removing 300 due to reco problems

my @read_types = ("SE", "PE", "SEwLR");


my %reco_matrix;
my @exp_types;

foreach my $read_type (@read_types) {
    foreach my $range (@ranges) {

        my $audit2_summary_file = "${read_type}_${range}.audit2_summary";
        
        my $exp_type = "${read_type}_${range}";
        &add_to_matrix($exp_type, $audit2_summary_file, \%reco_matrix);
        
        push (@exp_types, $exp_type);
    }
}

print "\t" . join("\t", @exp_types) . "\n";
foreach my $gene (sort keys %reco_matrix) {
    my @vals = ($gene);
    foreach my $exp_type (@exp_types) {
        my $reco_flag = $reco_matrix{$gene}->{$exp_type};
        unless (defined $reco_flag) {
            die "Error, missing result for $gene / $exp_type ";
        }
        push (@vals, $reco_flag);
    }
    print join("\t", @vals) . "\n";
}


exit(0);

####
sub add_to_matrix {
    my ($exp_token, $summary_file, $reco_matrix_href) = @_;
    
    open(my $fh, $summary_file) or die "Error, cannot open file: $summary_file";
    while(<$fh>) {
        chomp;
        unless (/\w/) { next; }
        if (/^Total_Genes/) { 
            ## local summary, stop here.
            last;
        }
        
        if (/^gene_id/) { next; }
        my ($gene_id, $reco_gene_flag, $num_refseqs, $num_FL_trin, $num_extra_trin) = split("\t");
        
        if ($reco_gene_flag eq "YES") {
            $reco_matrix_href->{$gene_id}->{$exp_token} = 1;
        }
        else {
            $reco_matrix_href->{$gene_id}->{$exp_token} = 0;
        }
        
    }
    
    return;
}
