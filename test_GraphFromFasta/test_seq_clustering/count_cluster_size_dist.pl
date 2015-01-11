#!/usr/bin/env perl

use strict;
use warnings;

my $usage = "usage: $0 pools.txt\n\n";

my $pools_file = $ARGV[0] or die $usage;


main: {
    
    my %counter;

    open (my $fh, $pools_file) or die $!;
    while (<$fh>) {
        chomp;
        my @counts = split(/\s+/);
        
        my $size = scalar(@counts);
        $counter{$size}++;
    }

    close $fh;

    foreach my $size (sort {$a<=>$b} keys %counter) {
        my $count = $counter{$size};

        print join("\t", $size, $count) . "\n";
    }

    exit(0);
    
}


                      
