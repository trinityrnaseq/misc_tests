#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;


## we delete all files we don't need in this directory. Be careful in case users try running it somewhere else, outside this dir.
chdir $FindBin::Bin or die "error, cannot cd to $FindBin::Bin";



my @files_to_keep = qw (
SP2.chr.bam
SP2.chr.fa.gz
cleanme.pl
mm9chr17.annotation.bed.gz
mm9chr17.fasta.gz
mm9chr17.tophat.bam
run_mm9_prep.sh
run_SP2_prep.sh
SP2.annot.bed.gz
run_SP2_prep_w_jaccard.sh
SP2.chr.SE.sam.gz
                        );


my %keep = map { + $_ => 1 } @files_to_keep;


foreach my $file (<*>) {
	
	if (! $keep{$file}) {
		print STDERR "-removing file: $file\n";
		unlink($file);
	}
}

`rm -rf Dir*`;


exit(0);
