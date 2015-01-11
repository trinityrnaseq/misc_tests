#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../trunk/PerlLib/");
use Fasta_reader;
use Cwd;


my $usage = "\n\n\tusage: $0 paralog_targets.txt\n\n";

my $paralog_targets = $ARGV[0] or die $usage;

unless ($ENV{TRINITY_HOME}) {
    $ENV{TRINITY_HOME} = "$FindBin::Bin/../../trunk/";
}

my $COUNTER = 0;

main: {
    
    if (! -e "paralogs.fasta") {
        &process_cmd("gunzip -c paralogs.fasta.gz > paralogs.fasta");
    }

    my $fasta_reader = new Fasta_reader("paralogs.fasta");
    my %fasta_seqs = $fasta_reader->retrieve_all_seqs_hash();

    
    my @paralogs;
    {
        open (my $fh, $paralog_targets) or die $!;
        while (<$fh>) {
            chomp;
            my ($para_A, $para_B) = split(/\s+/);
            push (@paralogs, [$para_A, $para_B]);
        }
        close $fh;
    }

    unless (-d "paralog_testing") {
        mkdir("paralog_testing") or die $!;
    }

    foreach my $paralog_pair (@paralogs) {
        my ($paralog_A, $paralog_B) = @$paralog_pair;
        my $para_A_seq = $fasta_seqs{$paralog_A} or die "Error, no seq for $paralog_A";
        my $para_B_seq = $fasta_seqs{$paralog_B} or die "Error, no seq for $paralog_B";
        &process_paralogs_run_trinity($paralog_A, $paralog_B, $para_A_seq, $para_B_seq);
    }
    

    exit(0);
}


####
sub process_paralogs_run_trinity {
    my ($paralog_A, $paralog_B, $paralog_A_seq, $paralog_B_seq) = @_;
    
    my $basedir = cwd();
    
    $COUNTER++;

    my $dir_tok = $COUNTER . "__" . join("^^", sort($paralog_A, $paralog_B));
    
    my $workdir = "paralog_testing/$dir_tok";

    unless (-d $workdir) {
        mkdir $workdir or die "Error, cannot mkdir $workdir";
    }
    chdir $workdir or die "Error, cannot cd to $workdir";
    
    # write ref fasta seqs.
    open (my $ofh, ">refseqs.fa") or die $!;
    print $ofh ">$paralog_A\n$paralog_A_seq\n"
        . ">$paralog_B\n$paralog_B_seq\n";
    close $ofh;

    # simulate reads:
    my $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.pl --transcripts refseqs.fa";
    &process_cmd($cmd);

    # run Trinity
    $cmd = "$ENV{TRINITY_HOME}/Trinity --seqType fa --SS_lib_type FR --JM 1G --no_cleanup --left reads.left.simPE.fa --right reads.right.simPE.fa --CPU 2 --bfly_opts \"--dont-collapse-snps --generate_intermediate_dot_files --stderr -V 10 \" ";
    &process_cmd($cmd);


    # generate sequence graphs just refseqs
    $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa --graph refseqs.dot";
    &process_cmd($cmd);


    # generate sequence graphs just refseqs
    $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa,trinity_out_dir/inchworm.K25.L25.fa --graph refseqs_w_iworm.dot";
    &process_cmd($cmd);
    

    # generate sequence graphs combining all
    $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa,trinity_out_dir/inchworm.K25.L25.fa,trinity_out_dir/Trinity.fasta --graph all_compare.dot";
    &process_cmd($cmd);


    # compare refseqs to the trinity assemblies
    $cmd = "$FindBin::Bin/util/illustrate_ref_comparison.pl refseqs.fa trinity_out_dir/inchworm.K25.L25.fa 95 | tee ref_iworm_compare.ascii_illus";
    &process_cmd($cmd);
    

    # compare refseqs to the trinity assemblies
    $cmd = "$FindBin::Bin/util/illustrate_ref_comparison.pl refSeqs.fa trinity_out_dir/Trinity.fasta 98 | tee ref_compare.ascii_illus";
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
    

    
