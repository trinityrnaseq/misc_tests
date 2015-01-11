#!/usr/bin/env perl

use strict;
use warnings;


main: {

    my @gzipped_files = qw(comp954.iworm_bundle.gz
comp954.out.gz
comp954.raw.fasta.gz
comp954.raw.graph.gz
comp954.reads.gz
);
    
    foreach my $gzipped_file (@gzipped_files) {
        my $unzipped_file = $gzipped_file;
        $unzipped_file =~ s/\.gz$//;
        
        if (-s $gzipped_file && ! -s $unzipped_file) {
            &process_cmd("gunzip -c $gzipped_file > $unzipped_file");
        }
    }
    
    my $cmd = "java -jar ../../Butterfly/Butterfly.jar -N 7100010 -L 200 -F 500 -C comp954 --max_number_of_paths_per_node=10 --path_reinforcement_distance=75";
    
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

    return;
}
