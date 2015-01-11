#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

my $usage = "usage: $0 fa_list.file [runPrep.pl params]\n\n";

my $fa_list_file = $ARGV[0] or die $usage;
shift @ARGV;

main: {
    open (my $fh, $fa_list_file) or die $!;
    while (<$fh>) {
        chomp;
        my $fa_file = $_;

        my $cmd = "$FindBin::Bin/runPrep.pl -R $fa_file -O $fa_file.dir -L 100 --strict --always_purge @ARGV";
        
        print "$cmd\n";
    }
    
    close $fh;
    
    exit(0);
}

