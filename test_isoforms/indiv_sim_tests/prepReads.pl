#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);


my $usage = "\tusage: $0 refSeqs.fa\n\n";

my $refSeqs_file = $ARGV[0] or die $usage;

main: {

    ## generate the simulated reads:
    my $REQUIRE_PROPER_PAIRS = 1;
    my $INCLUDE_VOLCANO_SPREAD = 1;
    
    my $cmd = "../../../trinityrnaseq/util/misc/run_read_simulator_per_fasta_entry.pl $refSeqs_file $REQUIRE_PROPER_PAIRS $INCLUDE_VOLCANO_SPREAD";
    &process_cmd($cmd);
    
    ## get list of reads
    $cmd = "find sim_data -regex \".\*template.fa\" | tee target_files.list";
    &process_cmd($cmd);

    
}


exit(0);


####
sub process_cmd { 
    my ($cmd) = @_;
    
    print STDERR "CMD: $cmd\n";

    my $ret = system($cmd);
    if ($ret) {
        die "Error, cmd: $cmd died with ret $ret";
    }

    return;
}

