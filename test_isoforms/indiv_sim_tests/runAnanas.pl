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
#  --threads <int>             number of parallel ananas jobs to run (each using one thread)
#
#  --target_list <filename>    file containing list of targeted fasta sequences
#  
#  
#################################################################################


__EOUSAGE__

    ;


my $help_flag;
my $target_list_file;
my $num_threads = 1;


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

unless ($target_list_file) {
    die $usage;
}


my $Ananas = `which Ananas`;
unless ($Ananas =~ /\w/) {
    die "Error, cannot find path to Ananas";
}
chomp $Ananas;

my @target_files = `cat $target_list_file`;
chomp @target_files;


my @align_commands;

my $ananas_cmds_file = "ananas.cmds";
open (my $ofh, ">ananas.cmds") or die $!;
foreach my $file (@target_files) {
    
    my $outdir = dirname($file);
    my $ananas_outdir .= "$outdir/ananas_out_dir";

    
    my $both_file = "$file.both.simPE.fa";
    unless (-e $both_file) {
        &process_cmd("cat $file.left.simPE.fa $file.right.simPE.fa > $both_file");
    }
    
    my $ananas_outfile = "$ananas_outdir/final.fa";
    unless (-s $ananas_outfile) {
        my $cmd = "bash -c \"$Ananas -i $both_file -dir fr -o $ananas_outdir\"";
        
        print $ofh "$cmd\n";
    }

    
    my $ananas_blat_outdir = "$outdir/ananas_blat";
    unless (-d $ananas_blat_outdir) {
        my $align_command = "$FindBin::Bin/../../../trunk/util/misc/BLAT_to_SAM.pl  --single $ananas_outfile --seqType fa --num_top_hits 1 --target $file -o $ananas_blat_outdir";
        push (@align_commands, $align_command);
    }
    
    
}
close $ofh;


## run cmds in parallel:
if (-s $ananas_cmds_file) {
    my $cmd = "ParaFly -c $ananas_cmds_file -CPU $num_threads";
    &process_cmd($cmd);
}

&process_cmd("find sim_data/ -regex \".*final.fa\" | ../../../trunk/util/support_scripts/GG_trinity_accession_incrementer.pl > ananas.fasta");


## align the fasta back to the reference:
if (@align_commands) {
    my $ananas_align_commands_file = "ananas_align.cmds";
    open (my $ofh, ">$ananas_align_commands_file") or die $!;
    print $ofh join("\n", @align_commands) . "\n";
    
    my $cmd = "ParaFly -c $ananas_align_commands_file -CPU $num_threads";
    &process_cmd($cmd);
}




print STDERR "Done. See ananas.fasta\n";

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

