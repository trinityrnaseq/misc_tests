#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;


## we delete all files we don't need in this directory. Be careful in case users try running it somewhere else, outside this dir.
chdir $FindBin::Bin or die "error, cannot cd to $FindBin::Bin";



my @files_to_keep = qw (
cleanme.pl
known_expr_vals.txt
notes
run_RSEM.sh
run_Trinity_EM.sh
simul.genome.sam.coordSorted.bam
simul.genome.sam.coordSorted.bam.bai
simul.genome.sam.coordSorted.sam.gz
simul.genome.sam.gz
simul.transcriptome.cdnas.fai
simul.transcriptome.cdnas.gz
simul.transcriptome.sam.coordSorted.bam
simul.transcriptome.sam.coordSorted.sam.gz
simul.transcriptome.sam.gz
simul.transcriptome.sam.nameSorted.bam
simul.transcriptome.sam.nameSorted.sam.gz
                        );


my %keep = map { + $_ => 1 } @files_to_keep;


foreach my $file (<*>) {
	
	if (! $keep{$file}) {
		print STDERR "-removing file: $file\n";
		unlink($file);
	}
}

`rm -rf RSEM.stat`;


exit(0);
