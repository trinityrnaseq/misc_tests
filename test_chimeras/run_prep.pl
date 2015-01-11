#!/usr/bin/env perl

use strict;
use warnings;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;
use Thread_helper;
use threads;

use Cwd;

my $usage = "\n\n\tusage: $0 num_threads [include_refSeqs]\n\n";

my $num_threads = $ARGV[0] or die $usage;
my $include_refseqs_flag = $ARGV[1]  || 0;


my $BASEDIR = cwd();
my $workdir = "$BASEDIR/chimtests";
if (! -d $workdir) {
    mkdir $workdir or die "Error, cannot mkdir $workdir";
}

my %chim_seqs;
{
    my $fasta_reader = new Fasta_reader("chims300.fa");
    %chim_seqs = $fasta_reader->retrieve_all_seqs_hash();
}

my %ref_seqs;
{
    my $fasta_reader = new Fasta_reader("refSeqs.fa");
    %ref_seqs = $fasta_reader->retrieve_all_seqs_hash();
}


main: {   

    my $thread_helper = new Thread_helper($num_threads);

    foreach my $chim_acc (keys %chim_seqs) {
        
        $thread_helper->wait_for_open_thread();
        
        my $thread = threads->create(\&run_assembly, $chim_acc);
        $thread_helper->add_thread($thread);
    }
    $thread_helper->wait_for_all_threads_to_complete();
    
    
    print STDERR "\n\nDone.\n\n";
    
    exit(0);
}



####
sub run_assembly {
    my ($chim_acc) = @_;
            
        
    my ($chim_pt_A, $chim_pt_B) = split(/--/, $chim_acc);
    
    my $chim_dir = "$workdir/$chim_acc";
    
    if (! -d $chim_dir) {
        mkdir($chim_dir) or die "Error, cannot mkdir $chim_dir";
    }
        
    my $target_seqs_file = "$chim_dir/targets.fa";
    
    if (! -s $target_seqs_file) {
        open (my $ofh, ">$target_seqs_file") or die "Error, cannot write to $target_seqs_file";
        
        my $chim_seq = $chim_seqs{$chim_acc} or die "Error, no seq for $chim_acc";
        print $ofh ">$chim_acc\n$chim_seq\n";
        
        my $A_seq = $ref_seqs{$chim_pt_A} or die "Error, no seq for $chim_pt_A";
        print $ofh ">$chim_pt_A\n$A_seq\n";
        
        my $B_seq = $ref_seqs{$chim_pt_B} or die "Error, no seq for $chim_pt_B";
        print $ofh ">$chim_pt_B\n$B_seq\n";
        
        close $ofh;
    }
    
    ## simulate reads:
    my $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.pl --transcripts $target_seqs_file --out_prefix $chim_dir/reads";
    my $sim_reads_checkpoint = "$chim_dir/sim_reads.ok";
    if (! -e $sim_reads_checkpoint) {
        &process_cmd("echo $cmd > $chim_dir/sim_reads.cmd");
        &process_cmd($cmd);

        if ($include_refseqs_flag) {
            &process_cmd("cat $target_seqs_file >> $chim_dir/reads.left.simPE.fa");
        }
                
        &process_cmd("touch $sim_reads_checkpoint");



    }
    
    ## run Trinity:
    $cmd = "$ENV{TRINITY_HOME}/Trinity --seqType fa --left $chim_dir/reads.left.simPE.fa --right $chim_dir/reads.right.simPE.fa --SS_lib_type FR --JM 2G --CPU 4  --bfly_opts '--generate_intermediate_dot_files' --bfly_jar ~/Bfly.jar --output $chim_dir/trinity_out_dir --min_glue 0 --no_bowtie ";
    
    my $trinity_checkpoint = "$chim_dir/Trinity.ok";
    if (! -e $trinity_checkpoint) {
        &process_cmd("echo $cmd > $chim_dir/Trinity.cmd");
        &process_cmd($cmd);
        &process_cmd("touch $trinity_checkpoint");
    }
    

    ## do FL analysis
    $cmd = "$ENV{TRINITY_HOME}/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target $target_seqs_file --query $chim_dir/trinity_out_dir/Trinity.fasta --reuse --out_prefix $chim_dir/FL.test  --allow_non_unique_mappings | tee $chim_dir/FL_analysis.txt";
    if (! -s "$chim_dir/FL_analysis.txt") {
        &process_cmd("echo $cmd > $chim_dir/FL.cmd");
        &process_cmd($cmd);

    }
    
    ## run evaluation:
    $cmd = "$ENV{TRINITY_HOME}/util/misc/illustrate_ref_comparison.pl $target_seqs_file $chim_dir/trinity_out_dir/Trinity.fasta 98 5 | tee $chim_dir/eval.illustration.txt";
    if (! -s "$chim_dir/eval.illustration.txt") {
        &process_cmd("echo $cmd > $chim_dir/eval.cmd");
        &process_cmd($cmd);
        &process_cmd("cat $chim_dir/FL_analysis.txt >> $chim_dir/eval.illustration.txt");
    }
    
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


        
        
    
