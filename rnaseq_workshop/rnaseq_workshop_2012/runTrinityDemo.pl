#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;
use FindBin;
use Cwd;

use Getopt::Long qw(:config no_ignore_case bundling pass_through);


my $usage = <<__EOUSAGE__;

#################################################################################
#
#  --GV              use genome-view instead of IGV
#
#  --DE              process two samples, perform DE analysis using cuffdiff
#
#  -I                interactive (prompts user at each step).
#
#################################################################################




__EOUSAGE__

    ;



my $help_flag = 0;

my $use_GV_flag = 0;
my $run_DE_flag = 0;
my $INTERACTIVE_MODE = 0;


&GetOptions( 'help|h' => \$help_flag,
             
             'IGV' => \$use_GV_flag,
             'DE' => \$run_DE_flag,
             'I' => \$INTERACTIVE_MODE,
             
    );

if ($help_flag) {
    die $usage;
}



my $trinity_dir = $ENV{TRINITY_HOME} or die "Error, need env var TRINITY_HOME set to Trinity installation directory";
$ENV{PATH} .= ":$trinity_dir";  ## adding it to our PATH setting.

## check for env vars
if ($use_GV_flag) {
    unless (defined $ENV{GENOMEVIEW}) {
        die "Error, must set env var for GENOMEVIEW path";
    }
}
else {
    unless (defined $ENV{IGV}) {
        die "Error, must set env var for IGV path";
    }
}


my $OS_type = `uname`;

## first check for tools needed.

my @tools = qw (Trinity.pl
    bowtie
    tophat
    samtools
    gmap_build
    gmap
);

{
    my $missing_tool_flag = 0;
    foreach my $tool (@tools) {
        my $path = `which $tool`;
        unless ($path =~ /\w/) {
            print STDERR "Error, cannot find path to: $tool\n";
            $missing_tool_flag = 1;
        }
    }
    
    if ($missing_tool_flag) {
        die "\n\nTools must be in PATH setting before proceeding.\n\n";
    }

}



{ 
    ## unzip the gzipped files.
    foreach my $file (<*.gz>) {
        my $unzipped_file = $file;
        $unzipped_file =~ s/\.gz//;
        unless (-s $unzipped_file) {
            my $ret = system("gunzip -c $file > $unzipped_file");
            if ($ret) {
                die "Error, could not gunzip file $file";
            }
        }
    }
}


## create both.fa
&process_cmd("cat condA.left.fa condB.left.fa > both.left.fa") unless (-s "both.left.fa");
&process_cmd("cat condA.right.fa condB.right.fa > both.right.fa") unless (-s "both.right.fa");


# run Trinity.

&process_cmd("Trinity.pl --seqType fa --left both.left.fa --right both.right.fa --CPU 4 --JM 1G") unless (-s "trinity_out_dir/Trinity.fasta");

# Examine top of Trinity.fasta file
&process_cmd("head trinity_out_dir/Trinity.fasta");


# Get Trinity stats:
&process_cmd("$trinity_dir/util/TrinityStats.pl trinity_out_dir/Trinity.fasta");

## run gmap
unless (-s "trinity_gmap.sam" && -s "trinity_gmap.bam") {
    &process_cmd("gmap_build -d genome -D . -k 13 genome.fa");
    &process_cmd("gmap -D . -d genome trinity_out_dir/Trinity.fasta -f samse > trinity_gmap.sam");
    
    ## convert to bam file format
    &process_cmd("samtools view -Sb trinity_gmap.sam > trinity_gmap.bam");
    &process_cmd("samtools sort trinity_gmap.bam trinity_gmap");
    &process_cmd("samtools index trinity_gmap.bam");
}


## align the rna-seq reads against the genome, too, for comparison 
unless (-s "tophat_out/accepted_hits.bam") {
    &process_cmd("bowtie-build genome.fa genome");
    &process_cmd("tophat -I 300 -i 20 --bowtie1 genome both.left.fa both.right.fa");
    &process_cmd("samtools index tophat_out/accepted_hits.bam");
}

## view using genomeview:

if ($use_GV_flag) {
    eval {
        &process_cmd("java -jar $ENV{GENOMEVIEW}/genomeview.jar genome.fa genes.bed `pwd`/tophat_out/accepted_hits.bam trinity_gmap.bam");
    };
}
else {
    # use IGV
    eval {
        &process_cmd("java -jar $ENV{IGV}/igv.jar -g `pwd`/genome.fa `pwd`/genes.bed,`pwd`/tophat_out/accepted_hits.bam,`pwd`/trinity_gmap.bam");
    };

}


unless ($run_DE_flag) {
    exit(0); # stop here
}


## Abundance estimation using RSEM
unless (-s "condA.isoforms.results") {

    
    &process_cmd("$trinity_dir/util/RSEM_util/run_RSEM_align_n_estimate.pl --seqType fa --left condA.left.fa --right condA.right.fa --transcripts trinity_out_dir/Trinity.fasta --prefix condA -- --no-bam-output");
    
}

unless (-s "condB.isoforms.results") {
    
    &process_cmd("$trinity_dir/util/RSEM_util/run_RSEM_align_n_estimate.pl --seqType fa --left condB.left.fa --right condB.right.fa --transcripts trinity_out_dir/Trinity.fasta --prefix condB -- --no-bam-output");

}


## generate matrix of counts:
&process_cmd("$trinity_dir/util/RSEM_util/merge_RSEM_frag_counts_single_table.pl condA.isoforms.results condB.isoforms.results > transcripts.counts.matrix");

## get trans lengths.
&process_cmd("cat condA.isoforms.results | cut -f1,3,4 > trans_lengths.txt");

## run edgeR
&process_cmd("$trinity_dir/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix transcripts.counts.matrix --method edgeR --no_eff_length --output edgeR") unless (-d "edgeR");


&process_cmd("ls edgeR/");
&process_cmd("head edgeR/transcripts.counts.matrix.condA_vs_condB.edgeR.DE_results");

&show("edgeR/transcripts.counts.matrix.condA_vs_condB.edgeR.DE_results.MA_n_Volcano.pdf");


## run TMM normalization:
&process_cmd("$trinity_dir/Analysis/DifferentialExpression/run_TMM_normalization_write_FPKM_matrix.pl --matrix transcripts.counts.matrix --lengths trans_lengths.txt");

chdir("edgeR") or die $!;

&process_cmd("$trinity_dir/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix ../transcripts.counts.matrix.TMM_normalized.FPKM") unless (-s "diffExpr.P0.001_C2.matrix.heatmap.pdf");

if ($OS_type =~ /linux/i) {
    &show("diffExpr.P0.001_C2.matrix.heatmap.pdf");
}
else {
    # mac 
    &show("diffExpr.P0.001_C2.matrix.heatmap.pdf\[0\]");
}

&process_cmd("$trinity_dir/Analysis/DifferentialExpression/define_clusters_by_cutting_tree.pl --Ptree 25 -R diffExpr.P0.001_C2.matrix.R.all.RData");
&show("diffExpr.P0.001_C2.matrix.R.all.RData.clusters_fixed_P_25/my_cluster_plots.pdf");


exit(0);

####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "\n\nCMD: $cmd\n";
    
    if ($INTERACTIVE_MODE) {
        print STDERR "-waiting... [PRESS ENTER TO PROCEED]  ";
        my $wait = <STDIN>;
        print STDERR "going.\n";
        
    }

    my $ret = system($cmd);
    if ($ret) {
        die "Error, cmd: $cmd died with ret $ret";
    }
    
    return;
}
    

sub show {
    my ($image) = @_;

    if ($OS_type =~ /linux/i) {
        ## use evince
        my $cmd = "evince $image";
        &process_cmd($cmd);
    }
    else {
        ## rely on ImageMagick:
        my $cmd = "display -background white -flatten $image";
        &process_cmd($cmd);
    }

    return;
}
