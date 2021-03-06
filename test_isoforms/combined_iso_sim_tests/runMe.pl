#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);



my $usage = <<__EOUSAGE__;

#####################################################################
#
#  Required:
#
#  --threads <int>         number of threads
#
#  --refSeqs <filename>    fasta file containing reference sequences
#  
#  Optional:
#
#  --bfly_opts <string>
#  --max_genes <int>       default: 100
#  
#  
#####################################################################


__EOUSAGE__

    ;


my $help_flag;
my $refSeqs_file;
my $num_threads;
my $max_genes = 100;
my $bfly_opts = "";


&GetOptions( 'h' => \$help_flag,
             'refSeqs=s' => \$refSeqs_file,
             'threads=i' => \$num_threads,
             'max_genes=i' => \$max_genes,
             'bfly_opts=s' => \$bfly_opts,
    );

if ($help_flag) {
    die $usage;
}

if (@ARGV) {
    die "Error, do not recognize params: @ARGV ";
}

unless ($num_threads && $refSeqs_file) {
    die $usage;
}


if (-d "sim_AS_data" && -s "read_files.list") {
    
    print STDERR "WARNING: REUSING EARLIER SIMULATED READ DATA\n";

}
else {

    ## generate the simulated reads:
    my $cmd = "$ENV{TRINITY_HOME}/util/misc/run_read_simulator_per_gene.pl $refSeqs_file $max_genes";
    &process_cmd($cmd);
    
    ## get list of reads
    $cmd = "find sim_AS_data -regex \".\*.info\" | tee read_files.list";
    &process_cmd($cmd);
}


my @read_files = `cat read_files.list`;
chomp @read_files;
    

unlink("cmds.list.completed");    
open (my $ofh, ">cmds.list") or die $!;
foreach my $file (@read_files) {
    
    my $outdir = dirname($file);
    $outdir .= "/trinity_out_dir";

    $file =~ s/\.info$//;

    if (-d $outdir) {
        print STDERR "-cleaning $outdir\n";
        `rm -rf $outdir`;
    }
    
    my $cmd = "$ENV{TRINITY_HOME}/Trinity --output $outdir --left $file.left.fa --right $file.right.fa --seqType fa --max_memory 1G  --CPU 1 --SS_lib_type FR --trinity_complete --verbose ";
    
    print $ofh "$cmd\n";
    

}

## run cmds in parallel:
my $cmd = "ParaFly -c cmds.list -CPU $num_threads";
eval {
    &process_cmd($cmd);
};

if ($@) {
    print STDERR $@;
}


#&process_cmd("find sim_AS_data/ -regex \".*allProbPaths.fasta\" | ../../../trunk/util/GG_trinity_accession_incrementer.pl > trin.fasta");

print STDERR "Done. See trin.fasta\n";

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

