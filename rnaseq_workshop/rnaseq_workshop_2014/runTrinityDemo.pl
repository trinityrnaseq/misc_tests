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
#  --autopilot         automatically run the pipeline end-to-end
#
#################################################################################


__EOUSAGE__

    ;


my $help_flag = 0;
my $AUTO_MODE = 0;


&GetOptions( 'help|h' => \$help_flag,
             'autopilot' => \$AUTO_MODE,
             
    );

if ($help_flag) {
    die $usage;
}



my $trinity_dir = $ENV{TRINITY_HOME} or die "Error, need env var TRINITY_HOME set to Trinity installation directory";
$ENV{PATH} .= ":$trinity_dir";  ## adding it to our PATH setting.

unless (defined $ENV{IGV}) {
    die "Error, must set env var for IGV path";
}

my $OS_type = `uname`;

## first check for tools needed.

my @tools = qw (Trinity
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


## create combined fq files
&process_cmd("cat Sp_ds.left.fq Sp_hs.left.fq Sp_log.left.fq Sp_plat.left.fq > ALL.LEFT.fq") unless (-s "ALL.LEFT.fq");
&process_cmd("cat Sp_ds.right.fq Sp_hs.right.fq Sp_log.right.fq  Sp_plat.right.fq > ALL.RIGHT.fq") unless (-s "ALL.RIGHT.fq");


# run Trinity.
&process_cmd("$trinity_dir/Trinity --seqType fq --SS_lib_type RF --left ALL.LEFT.fq --right ALL.RIGHT.fq --CPU 4 --JM 1G") unless (-s "trinity_out_dir/Trinity.fasta");

# Examine top of Trinity.fasta file
&process_cmd("head trinity_out_dir/Trinity.fasta");


# Get Trinity stats:
&process_cmd("$trinity_dir/util/TrinityStats.pl trinity_out_dir/Trinity.fasta");

## run gmap
unless (-s "trinity_gmap.sam" && -s "trinity_gmap.bam") {
    &process_cmd("gmap_build -d genome -D . -k 13 genome.fa");
    &process_cmd("gmap -n 0 -D . -d genome trinity_out_dir/Trinity.fasta -f samse > trinity_gmap.sam");
    
    ## convert to bam file format
    &process_cmd("samtools view -Sb trinity_gmap.sam > trinity_gmap.bam");
    &process_cmd("samtools sort trinity_gmap.bam trinity_gmap");
    &process_cmd("samtools index trinity_gmap.bam");
}


## align the rna-seq reads against the genome, too, for comparison 
unless (-s "tophat_out/accepted_hits.bam") {
    &process_cmd("bowtie-build genome.fa genome");
    &process_cmd("tophat -I 300 -i 20 --bowtie1 genome ALL.LEFT.fq ALL.RIGHT.fq");
    &process_cmd("samtools index tophat_out/accepted_hits.bam");
}

## view using genomeview:
# use IGV
eval {
    my $cmd = "java -Xmx2G -jar $ENV{IGV}/igv.jar -g `pwd`/genome.fa `pwd`/genes.bed,`pwd`/tophat_out/accepted_hits.bam,`pwd`/trinity_gmap.bam";
    if ($AUTO_MODE) {
        $cmd .= " & ";
    }
    &process_cmd($cmd);
};


###################################
## Abundance estimation using RSEM
###################################

my @samples = ("Sp_ds", "Sp_hs", "Sp_log", "Sp_plat");
my @rsem_result_files;

foreach my $sample (@samples) {

    my $rsem_result_file = "$sample.isoforms.results";
    push (@rsem_result_files, $rsem_result_file);
    
    unless (-s $rsem_result_file) {
        
        &process_cmd("$trinity_dir/util/align_and_estimate_abundance.pl --seqType fq --left $sample.left.fq --right $sample.right.fq --transcripts trinity_out_dir/Trinity.fasta --output_prefix $sample --est_method RSEM --aln_method bowtie --trinity_mode --prep_reference");
        
    }
    
    if ($sample eq "Sp_ds") {
        &process_cmd("head Sp_ds.isoforms.results");
    }
    

}

## generate matrix of counts:
&process_cmd("$trinity_dir/util/abundance_estimates_to_matrix.pl --est_method RSEM --out_prefix Trinity_trans @rsem_result_files");

## get trans lengths.
&process_cmd("cat Sp_ds.isoforms.results | cut -f1,3,4 > trans_lengths.txt");

## run edgeR
&process_cmd("$trinity_dir/Analysis/DifferentialExpression/run_DE_analysis.pl --matrix Trinity_trans.counts.matrix --method edgeR --output edgeR") unless (-d "edgeR");


&process_cmd("ls edgeR/");
&process_cmd("head edgeR/Trinity_trans.counts.matrix.Sp_log_vs_Sp_plat.edgeR.DE_results");

&show("edgeR/Trinity_trans.counts.matrix.Sp_log_vs_Sp_plat.edgeR.DE_results.MA_n_Volcano.pdf");

&process_cmd("sed '1,1d' edgeR/Trinity_trans.counts.matrix.Sp_log_vs_Sp_plat.edgeR.DE_results | awk '{ if (\$5 <= 0.05) print;}' | wc -l");


## run TMM normalization:
&process_cmd("$trinity_dir/Analysis/DifferentialExpression/run_TMM_normalization_write_FPKM_matrix.pl --matrix Trinity_trans.counts.matrix --lengths trans_lengths.txt");

chdir("edgeR") or die $!;

&process_cmd("$trinity_dir/Analysis/DifferentialExpression/analyze_diff_expr.pl --matrix ../Trinity_trans.counts.matrix.TMM_normalized.FPKM -P 1e-3 -C 2") unless (-s "diffExpr.P0.001_C2.matrix.heatmap.pdf");


&process_cmd("wc -l diffExpr.P1e-3_C2.matrix"); # number of DE transcripts + 1


if ($OS_type =~ /linux/i) {
    &show("diffExpr.P1e-3_C2.matrix.log2.centered.genes_vs_samples_heatmap.pdf");
}
else {
    # mac 
    &show("diffExpr.P1e-3_C2.matrix.log2.centered.genes_vs_samples_heatmap.pdf\[0\]");
}

&process_cmd("$trinity_dir/Analysis/DifferentialExpression/define_clusters_by_cutting_tree.pl --Ptree 60 -R diffExpr.P1e-3_C2.matrix.RData");
&show("diffExpr.P1e-3_C2.matrix.RData.clusters_fixed_P_60/my_cluster_plots.pdf");

exit(0);

####
sub process_cmd {
    my ($cmd) = @_;

    unless ($AUTO_MODE) {
        
        my $response = "";
        while ($response !~ /^[YN]/i) {
            print STDERR "\n\n"
                . "###############################################\n"
                . "CMD: $cmd\n"
                . "###############################################\n\n"
                . "Execute (Y/N)? ";

            $response = <STDIN>;
        }

        if ($response =~ /^N/i) {
            print STDERR "\t *** Exiting on demand. ****\n\n"
                . "Goodbye. \n\n\n";
            exit(0);
        }
    }
    
    print STDERR "\tNow running:\n\t\t$cmd\n\n\n";
    
    my $ret = system($cmd);
    if ($ret) {
        die "Error, cmd: $cmd died with ret $ret";
    }
    
    return;
}


sub show {
    my ($image) = @_;

    my $cmd;

    if ($OS_type =~ /linux/i) {
        ## use evince
        $cmd = "evince $image";
    }
    else {
        ## rely on ImageMagick:
        $cmd = "display -background white -flatten $image";
    }
    
    if ($AUTO_MODE) {
        $cmd .= " & ";
    }
    
    &process_cmd($cmd);

    return;
}
