#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../trunk/PerlLib/");
use Fasta_reader;
use Cwd;


my $usage = "usage: $0 num_seqs_to_test\n\n";

my $NUM_SEQS_TO_TEST = $ARGV[0] or die $usage;

my $ref_trans_fa = "mouse.refSeq.longest_iso.fa";


unless ($ENV{TRINITY_HOME}) {
    $ENV{TRINITY_HOME} = "$FindBin::Bin/../../trunk/";
}

my $UTIL_DIR = "$FindBin::Bin/util";

main: {
    
    if (! -e $ref_trans_fa) {
        &process_cmd("gunzip -c $ref_trans_fa.gz > $ref_trans_fa");
    }

    my $fasta_reader = new Fasta_reader($ref_trans_fa);
    my %fasta_seqs = $fasta_reader->retrieve_all_seqs_hash();
        
    unless (-d "testing_dir") {
        mkdir("testing_dir") or die $!;
    }
    
    my $counter = 0;
    foreach my $acc (keys %fasta_seqs) {
        my $seq = $fasta_seqs{$acc};
        &execute_seq_pipe($acc, $seq);

        $counter++;
        if ($counter >= $NUM_SEQS_TO_TEST) {
            last;
        }

    }

    

    exit(0);
}


####
sub execute_seq_pipe {
    my ($acc, $seq) = @_;
    
    my $basedir = cwd();
    
    my $dir_tok = $acc;
    $dir_tok =~ s/\W/_/g;
    
    my $workdir = "testing_dir/$dir_tok";

    unless (-d $workdir) {
        mkdir $workdir or die "Error, cannot mkdir $workdir";
    }
    chdir $workdir or die "Error, cannot cd to $workdir";
    
    # write ref fasta seqs.
    open (my $ofh, ">refseqs.fa") or die $!;
    print $ofh ">$acc\n$seq\n";
    close $ofh;
    
    # extract kmers
    my $cmd = "$UTIL_DIR/get_kmers.pl refSeqs.fa > kmers.dirOrient.fa";
    &process_cmd($cmd);
    
    $cmd = "$UTIL_DIR/random_revcomp_kmers.pl kmers.dirOrient.fa > kmers.randOrient.fa";
    &process_cmd($cmd);
        
    # run inchworm
    $cmd = "$ENV{TRINITY_HOME}/Inchworm/bin/inchworm --kmers kmers.randOrient.fa --run_inchworm --DS > iworm.fa";
    &process_cmd($cmd);
    
    # compare refseqs to iworm contigs
    $cmd = "$ENV{TRINITY_HOME}/util/misc/illustrate_ref_comparison.pl refSeqs.fa iworm.fa 98 | tee ref_compare.ascii_illus";
    &process_cmd($cmd);
    
    chdir $basedir or die "Error, cannot cd back to $basedir";

    return;

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
    

    
