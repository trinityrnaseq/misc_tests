#!/usr/bin/env perl

use strict;
use warnings;


my $usage = "usage: $0 A.FL_selected B.FL_selected\n\n";

my $A_FL_selected = $ARGV[0] or die $usage;
my $B_FL_selected = $ARGV[1] or die $usage;

main: {

    my %FL_A = &parse_FL($A_FL_selected);

    my %FL_B = &parse_FL($B_FL_selected);

    my %all_FL_targets = map { + $_ => 1 } (keys %FL_A, keys %FL_B);

    foreach my $target (sort keys %all_FL_targets) {
        
        my $trinity_A = $FL_A{$target} || "NA";
        my $trinity_B = $FL_B{$target} || "NA";

        print join("\t", $target, $trinity_A, $trinity_B) . "\n";
    }


    exit(0);
    

}



####
sub parse_FL {
    my ($file) = @_;

    my %target_to_trinity;

    open (my $fh, $file) or die $!;
    while (<$fh>) {
        chomp;
        my @x = split(/\t/);
        my $trinity_acc = $x[9];
        my $target_trans = $x[13];
        
        $target_to_trinity{$target_trans}= $trinity_acc;
    }
    close $fh;


    return(%target_to_trinity);
}
