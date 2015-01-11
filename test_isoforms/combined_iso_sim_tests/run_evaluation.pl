#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 refSeqs.fa\n\n";

my $refSeqs_fa = $ARGV[0] or die $usage;

main: {

    my $cmd = "../../../trunk/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target $refSeqs_fa --query trin.fasta";
    
    &process_cmd($cmd);
    

    exit(0);
    
}

####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "CMD: $cmd\n";

    my $ret = system($cmd);

    if ($ret) {
        die "Error, cmd: $cmd died with ret $ret";
    }

}

