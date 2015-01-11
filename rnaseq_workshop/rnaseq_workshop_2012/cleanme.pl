#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

my $FULL_CLEAN = $ARGV[0] || 0;


## we delete all files we don't need in this directory. Be careful in case users try running it somewhere else, outside this dir.
chdir $FindBin::Bin or die "error, cannot cd to $FindBin::Bin";




my @files_to_keep = qw (cleanme.pl 
condA.left.fa.gz
condA.right.fa.gz
condB.left.fa.gz
condB.right.fa.gz
genes.bed
genes.cdna.gz
genes.gff3
genes.pep.gz
genome.1.ebwt.gz
genome.2.ebwt.gz
genome.3.ebwt.gz
genome.4.ebwt.gz
genome.fa.fai
genome.fa.gz
genome.rev.1.ebwt.gz
genome.rev.2.ebwt.gz

runTrinityDemo.pl
runTuxedoDemo.pl
__runCummeRbund.R
cummeRbund.demo.R

docs

genome.1.bt2.gz
genome.2.bt2.gz
genome.3.bt2.gz
genome.4.bt2.gz
genome.rev.1.bt2.gz
genome.rev.2.bt2.gz

);                      


my %keep = map { + $_ => 1 } @files_to_keep;


foreach my $file (<*>) {
	
	if (! $keep{$file}) {
		print STDERR "-removing file: $file\n";
		
        if (-f $file) {
            unlink($file);
        }
        elsif (-d $file) {
            if ($file =~ /trinity_out_dir/) {
                if ($FULL_CLEAN) {
                `rm -rf $file`;
                }
                else {
                    unlink "trinity_out_dir/Trinity.fasta";
                }
            }
            else {
                `rm -rf $file`;
            }
        }
    }
}



exit(0);
