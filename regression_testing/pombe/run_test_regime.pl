#!/usr/bin/env perl

use strict;
use warnings;



my $read_data = "schizo_10M_set.tgz";
my $data_url = "http://sourceforge.net/projects/trinityrnaseq/files/misc/schizo_10M_set.tgz/download";

main: {

    if (! -s "$read_data") {
        &process_cmd("wget $data_url");
    }
    &process_cmd("tar -zxvf $read_data") unless (-s "schizo_10M_set/10M.left.fq");
    
    my $trinity_cmd = "../../../trunk/Trinity.pl "
        . " --seqType fq --left schizo_10M_set/10M.left.fq --right schizo_10M_set/10M.right.fq "
        . " --JM 20G --CPU 6 --SS_lib_type RF "
        . " --monitoring ";
    
    &process_cmd($trinity_cmd);
    
    ## run evaluations of results
    



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
