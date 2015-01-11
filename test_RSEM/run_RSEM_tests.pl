#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;
use FindBin;

main: {

    my $basedir = $FindBin::Bin;

    foreach my $testdir qw (paired_F200_R50
                            paired_F500_R50
                            single_F100_R50
                            single_F500_R50 ) {

        chdir($basedir) or die "Error, cannot cd to $basedir";
        
        chdir ($testdir) or die "Error, cannot chdir to $testdir";
        
        if (-s "known_vs_rsem_plot.pdf") { next; }
        
        my $ret = system("/bin/bash ./run_RSEM.sh");
        if ($ret) {
            die "Error, couldnt execute test in $testdir";
        }
    }


    print "All tests completed.  See .pdf files in test directories for comparisons.\n";
    
    exit(0);
}


            
