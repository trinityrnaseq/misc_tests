#!/usr/bin/env perl

use strict;
use warnings;
use Cwd;
use FindBin;

my $usage = "usage: $0 fasta_file_targets.list.txt output_basedir [eval cmds]\n\n";

my $files_listing_file = $ARGV[0] or die $usage;
my $output_basedir = $ARGV[1] or die $usage;
shift @ARGV;
shift @ARGV;


main: {


    my @files = `cat $files_listing_file`;
    chomp @files;

    my $eval_script = "$FindBin::Bin/run_Trinity_eval.sh";
    my $basedir = cwd();

    unless ($output_basedir =~ /^\//) {
        $output_basedir = "$basedir/$output_basedir";
    }
    
    foreach my $file (@files) {
        
        my @pts = split(/\//, $file);
        my $gene_name = $pts[-2];

        unless ($file =~ /^\//) {
            $file = "$basedir/$file";
        }
        
        my $cmd = "$eval_script -R $file -O $output_basedir/$gene_name @ARGV";
        
        print "$cmd\n";
    }

    exit(0);
}


