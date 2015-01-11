#!/usr/bin/env perl

use strict;
use warnings;


my %gene_to_iso;
{
    open (my $fh, "refSeqs.fa") or die $!;
    while (<$fh>) {
        chomp;
        if (/>(\S+)/) {
            my $acc = $1;
            my ($trans, $gene) = split(/;/, $acc);
            $gene_to_iso{$gene}->{$trans} = "NO";
        }
    }
    close $fh;
}

{
    open (my $fh, "trin.fasta.pslx.FL_selected") or die $!;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $acc = $x[13];
        
        my ($trans, $gene) = split(/;/, $acc);
        $gene_to_iso{$gene}->{$trans} = "YES";

    }
    close $fh;

}

foreach my $gene (keys %gene_to_iso) {
    my $trans_href = $gene_to_iso{$gene};
    
    print "$gene";

    foreach my $trans_acc (keys %$trans_href) {

        my $FL = $trans_href->{$trans_acc};

        print "\t$trans_acc:$FL";
    }
    print "\n";
}


exit(0);


