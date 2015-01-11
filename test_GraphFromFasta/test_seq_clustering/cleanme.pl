#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;


## we delete all files we don't need in this directory. Be careful in case users try running it somewhere else, outside this dir.
chdir $FindBin::Bin or die "error, cannot cd to $FindBin::Bin";



my @files_to_keep = qw (__control_clustering.txt
                        both.fa.gz
                        cleanme.pl
                        iworm.fa.gz
                        runTest.sh
                        count_cluster_size_dist.pl
                        runSmallTest.sh
                        test.iworm
                        test.reads

                        );


my %keep = map { + $_ => 1 } @files_to_keep;


foreach my $file (<*>) {
	
	if (! $keep{$file}) {
		print STDERR "-removing file: $file\n";
		unlink($file);
	}
}


exit(0);
