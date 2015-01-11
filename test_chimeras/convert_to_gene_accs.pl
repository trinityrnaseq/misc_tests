#!/usr/bin/env perl

use strict;
use warnings;

my @genes_to_trans = `cat genes_to_trans.txt`;
chomp @genes_to_trans;

my %t_to_g;
foreach my $line (@genes_to_trans) {

    my ($gene_id, $trans_id) = split(/\t/, $line);
    $t_to_g{$trans_id} = $gene_id;

}

my @chim_accs = `cat k`;
chomp @chim_accs;

foreach my $chim (@chim_accs) {
    my ($chim_A, $chim_B) = split(/--/, $chim);
    
    my $g1 = $t_to_g{$chim_A} or die $!;
    my $g2 = $t_to_g{$chim_B} or die $!;

    print "$g1--$g2\n";
}

exit(0);

