#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use SAM_reader;
use SAM_entry;

my $usage = "usage: $0 file.bam\n\n";

my $sam_file = $ARGV[0] or die $usage;

main: {

    my $sam_reader = new SAM_reader($sam_file);
    while(my $read = $sam_reader->get_next()) {

        my $read_name = $read->reconstruct_full_read_name();

        my $line = $read->get_original_line();

        if ($line =~ /NM:i:(\d+)/) {
            my $num_mm = $1;
            print "$read_name\t$num_mm\n";
        }
        else {
            die "Error, cannot find NM from $line";
        }
    }

    exit(0);
}

