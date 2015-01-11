#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);
use FindBin;
use lib ("$FindBin::Bin/../../../trunk/PerlLib");
use Pipeliner;


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

my @target_files = `cat $target_list_file`;
chomp @target_files;

    
open (my $ofh, ">cmds.list") or die $!;
foreach my $file (@target_files) {
    
    my $outdir = dirname($file);
    
    my $pipeliner = new Pipeliner();
    $pipeliner->add_commands( new Command("bowtie-build $file $file", "$file.bowtie-build.ok") );
    $pipeliner->add_commands( new Command("bowtie --threads $num_threads -X 10000 -S -f $file -1 $file.left.simPE.fa -2 $file.right.simPE.fa | samtools view -Sbo - - > $outdir/bowtie.bam", "$outdir/bowtie.bam.ok") );
    $pipeliner->add_commands( new Command("samtools sort $outdir/bowtie.bam $outdir/bowtie", "$outdir/bowtie.bam.sort.ok"));
    
    $pipeliner->add_commands( new Command("samtools index $outdir/bowtie.bam", "$outdir/bowtie.bam.bai.ok") );
    

    $pipeliner->run();
    
}
close $ofh;


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

