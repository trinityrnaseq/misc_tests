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

## first check for tools needed.

my @tools = qw (
    bowtie
    tophat
    cufflinks
    cuffcompare
    cuffmerge
    cuffdiff
    samtools
    R
    
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


{ 
    ## unzip the gzipped files.
    foreach my $file (<*.gz>) {
        my $unzipped_file = $file;
        $unzipped_file =~ s/\.gz//;
        unless (-s $unzipped_file) {
            my $ret = system("gunzip -c $file > $unzipped_file");
            if ($ret) {
                die "Error, guznip of $file died ";
            }
        }
    }
}


main: {
    
    ## condition A first
    &process_cmd("tophat -I 1000 -i 20 -o condA_tophat_out genome condA.left.fa condA.right.fa") unless (-s "condA_tophat_out/accepted_hits.bam");
    &process_cmd("samtools index condA_tophat_out/accepted_hits.bam") unless (-s "condA_tophat_out/accepted_hits.bam.bai");
    &process_cmd("cufflinks -o condA_cufflinks_out condA_tophat_out/accepted_hits.bam") unless -s ("condA_cufflinks_out/transcripts.gtf");
    
    if (! $run_DE_flag) {
        
        ## just highlight sample A results.
        if ($use_GV_flag) {
            eval {
                &process_cmd("java -jar $ENV{GENOMEVIEW}/genomeview.jar genome.fa genes.bed condA_cufflinks_out/transcripts.gtf condA_tophat_out/accepted_hits.bam");
            };
        }
        else {
            eval { 
                &process_cmd("java -jar $ENV{IGV}/igv.jar -g `pwd`/genome.fa `pwd`/condA_cufflinks_out/transcripts.gtf,`pwd`/genes.bed,`pwd`/condA_tophat_out/accepted_hits.bam");
            };
        }
        
    }
    else {
        ## must process condition B
        ## and run DE analysis
        
        &process_cmd("tophat -I 1000 -i 20 -o condB_tophat_out genome condB.left.fa condB.right.fa") unless (-s "condB_tophat_out/accepted_hits.bam");
        &process_cmd("samtools index condB_tophat_out/accepted_hits.bam") unless (-s "condB_tophat_out/accepted_hits.bam.bai");
        &process_cmd("cufflinks -o condB_cufflinks_out condB_tophat_out/accepted_hits.bam") unless (-s "condB_cufflinks_out/transcripts.gtf");
        
        unless (-s "assemblies.txt") {
            &process_cmd("echo condA_cufflinks_out/transcripts.gtf > assemblies.txt");
            &process_cmd("echo condB_cufflinks_out/transcripts.gtf >> assemblies.txt");
        }
        
        &process_cmd("cuffmerge -s genome.fa assemblies.txt") unless (-s "merged_asm/merged.gtf");
        
        if ($use_GV_flag) {
            eval {
                &process_cmd("java -jar $ENV{GENOMEVIEW}/genomeview.jar genome.fa merged_asm/merged.gtf genes.bed condA_tophat_out/accepted_hits.bam condB_tophat_out/accepted_hits.bam");
            };
        }
        else {
            eval { 
                &process_cmd("java -jar $ENV{IGV}/igv.jar -g `pwd`/genome.fa `pwd`/merged_asm/merged.gtf,`pwd`/genes.bed,`pwd`/condA_tophat_out/accepted_hits.bam,`pwd`/condB_tophat_out/accepted_hits.bam");
            };
        }
        

        &process_cmd("cuffdiff -o diff_out -b genome.fa -L condA,condB -u merged_asm/merged.gtf condA_tophat_out/accepted_hits.bam condB_tophat_out/accepted_hits.bam") unless (-e "diff_out/gene_exp.diff");
        
        &process_cmd("head diff_out/gene_exp.diff");
        
    }
    

    exit(0);


}


####
sub process_cmd {
    my ($cmd) = @_;

    print STDERR "\n\nCMD: $cmd\n";

    if ($INTERACTIVE_MODE) {
        print STDERR "-waiting...  [PRESS ENTER TO PROCEED]  ";
        my $wait = <STDIN>;
        print STDERR "going.\n";
        
    }

    my $ret = system($cmd);
    if ($ret) {
        die "Error, cmd: $cmd died with ret $ret";
    }
    
    return;
}

