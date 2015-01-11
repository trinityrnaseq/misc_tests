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
        
        my $ret = system("./cleanme.pl");
        if ($ret) {
            die "Error, couldnt execute cleanMe.pl in $testdir";
        }
    }


    print "All cleaned.\n";
    
    exit(0);
}


            
