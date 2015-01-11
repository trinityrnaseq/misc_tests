#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);

use FindBin;

my $usage = <<__EOUSAGE__;

#################################################################################
#
#  Required:
#
#  --threads <int>             number of threads
#
#  --target_list <filename>    file containing list of targeted fasta sequences
#  
#  
#################################################################################


__EOUSAGE__

    ;


my $help_flag;
my $target_list_file;
my $num_threads;


&GetOptions( 'h' => \$help_flag,
             'target_list=s' => \$target_list_file,
             'threads=i' => \$num_threads,
             );

if ($help_flag) {
    die $usage;
}

if (@ARGV) {
    die "Error, do not recognize params: @ARGV ";
}

unless ($num_threads && $target_list_file) {
    die $usage;
}

my @target_files = `cat $target_list_file`;
chomp @target_files;


my @align_commands;
    
my $trin_cmds_file = "trin.cmds.list";
open (my $ofh, ">$trin_cmds_file") or die $!;
foreach my $file (@target_files) {
    
    my $outdir = dirname($file);
    my $trin_outdir .= "$outdir/trinity_out_dir";


    my $trinity_out = "$trin_outdir/Trinity.fasta";
    unless (-s $trinity_out) {
        # avoid rerunning it.
        my $cmd = "../../../trunk/Trinity -o $trin_outdir --single $file --seqType fa --JM 1G  --SS_lib_type FR --left $file.left.simPE.fa --right $file.right.simPE.fa";
        print $ofh "$cmd\n";
    }

    my $trin_blat_outdir = "$outdir/trin_blat";
    unless (-d $trin_blat_outdir) {
        my $align_command = "$FindBin::Bin/../../../trunk/util/misc/BLAT_to_SAM.pl  --single $trinity_out --seqType fa --num_top_hits 1 --target $file -o $trin_blat_outdir";
        push (@align_commands, $align_command);
        
        
    }
    
}
close $ofh;


## run cmds in parallel:
my $cmd = "ParaFly -c $trin_cmds_file -CPU $num_threads";
&process_cmd($cmd) if (-s $trin_cmds_file);

&process_cmd("find sim_data/ -regex \".*allProbPaths.fasta\" | ../../../trunk/util/support_scripts/GG_trinity_accession_incrementer.pl > trin.fasta");


## align the fasta back to the reference:
if (@align_commands) {
    my $trin_align_commands_file = "trin_align.cmds";
    open (my $ofh, ">$trin_align_commands_file") or die $!;
    print $ofh join("\n", @align_commands) . "\n";
    
    my $cmd = "ParaFly -c $trin_align_commands_file -CPU $num_threads";
    &process_cmd($cmd);
}

    


exit(0);


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

