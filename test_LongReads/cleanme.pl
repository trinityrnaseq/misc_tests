#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;


## we delete all files we don't need in this directory. Be careful in case users try running it somewhere else, outside this dir.
chdir $FindBin::Bin or die "error, cannot cd to $FindBin::Bin";



my @files_to_keep = qw (cleanme.pl 

                        runPrep.pl
mouse.refSeq.longest_iso.fa.gz
mouse.refSeq.longest_iso.fa
notes
complex_transcripts_sampled.gencode.fasta.gz
complex_transcripts_sampled.gencode.fasta

gencode.v19.rna_seq_pipeline.gtf.wGeneNames.cdna.gz
gencode.v19.rna_seq_pipeline.gtf.wGeneNames.cdna
spawn_tests.pl
fa_files_to_prep_cmds.pl
                        );


my %keep = map { + $_ => 1 } @files_to_keep;



foreach my $file (<*>) {

    if ($file =~ /\.gz$/) { next; } # keep gz files.
	
	if (! $keep{$file}) {
		print STDERR "-removing file: $file\n";
		unlink($file);
	}
}


exit(0);
