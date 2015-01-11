#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;

my $usage = "\n\n\tusage: $0 target.fasta Bfly.jar (byGene|byTrans)\n\n";

my $target_fasta = $ARGV[0] or die $usage;
my $bfly_jar = $ARGV[1] or die $usage;
my $by_gene_or_trans = $ARGV[2] or die $usage;

unless ($by_gene_or_trans =~ /^(byGene|byTrans)$/) {
    die $usage;
}

main: {

    
    my $cmd_template = "$FindBin::Bin/runPrep.pl -R $target_fasta -B $bfly_jar";
    if ($by_gene_or_trans eq "byGene") {
        $cmd_template .= " --by_Gene";
    }
    
    ## FL-only
    my $cmd = $cmd_template . " --ref_trans_only -O refOnly > refOnly.log 2>&1";
    &process_cmd($cmd);

    ## reads-only
    $cmd = $cmd_template . " -O readsOnly > readsOnly.log 2>&1";
    &process_cmd($cmd);

    ## FL+reads
    $cmd = $cmd_template . " --incl_ref_trans -O inclFL > inclFL.log 2>&1";
    &process_cmd($cmd);


    exit(0);
}




####
sub process_cmd {
    my ($cmd) = @_;

    $cmd = "bsub -q regevlab -e err -o out -N -R \"rusage[mem=10]\" \"$cmd\" ";
    
    print STDERR "CMD: $cmd\n";
    my $ret = system($cmd);

    if ($ret) {
        die "Error, CMD: $cmd died with ret $ret";
    }

    return;
}
