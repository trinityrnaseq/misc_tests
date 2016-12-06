#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$ENV{TRINITY_HOME}/PerlLib/");
use Fasta_reader;
use Cwd;
use Data::Dumper;
use Carp;
use Getopt::Long qw(:config no_ignore_case bundling pass_through);
use List::Util qw (shuffle);

my $help_flag;
my $ref_trans_fa;
my $READ_LENGTH = 76;
my $FRAG_LENGTH = 300;

my $usage = <<__EOUSAGE__;

################################################################################
#
#  * Required:
#
#  --ref_trans|R <string>                 reference transcriptome
#
#  --out_dir|O <string>                   output directory name 
#
#  * Common Opts:
#
#  --read_length <int>                    read length (defalt: $READ_LENGTH)
#
#  --frag_length <int>                    fragment length (default: $FRAG_LENGTH)
#
#  * include FL seq opts:
#
#  * Misc Opts:
#
#  --wgsim                              use wgsim for simulating reads
#
#  --strand_specific                    sets to strand-specific mode (FR)  (! for use with wgsim)
#
####
#  ** Mutate the reads
#
#  --read_mut_rate <float>              simulated read error rate (default: 0)  (value between 0 and 0.25 allowed)
#
#  --ref_mut_insert_rate <float>        mutate insertions in the ref sequence (default: 0) ( values allowed 0<x<0.25)
#
#  --ref_mut_delete_rate <float>        mutate deletions in the ref sequence (default: 0)  ( values allowed 0<x<0.25)
#
#  --ref_mut_subst_rate <float>         mutate substitutions in ref seq (default: 0) (values allowed 0<x<0.25)
#
############################################################################################


__EOUSAGE__

    ;

my $READ_MUT_RATE = 0;

my $REF_MUT_INSERT_RATE = 0;
my $REF_MUT_DELETE_RATE = 0;
my $REF_MUT_SUBST_RATE = 0;


my $use_wgsim_flag = 0;
my $strand_specific_flag = 0;

my $OUT_DIR;

&GetOptions ( 'h' => \$help_flag,

              # required
              'ref_trans|R=s' => \$ref_trans_fa,
              
              # optional
              'out_dir|O=s' => \$OUT_DIR,

              'read_length=i' => \$READ_LENGTH,
              'frag_length=i' => \$FRAG_LENGTH,
              
              'read_mut_rate=f' => \$READ_MUT_RATE,
              
              'ref_mut_insert_rate=f' => \$REF_MUT_INSERT_RATE,
              'ref_mut_delete_rate=f' => \$REF_MUT_DELETE_RATE,
              'ref_mut_subst_rate=f' => \$REF_MUT_SUBST_RATE,
              
              'wgsim' => \$use_wgsim_flag,

              'strand_specific' => \$strand_specific_flag,
);


if ($help_flag) {
    die $usage;
}



unless ($ref_trans_fa && $OUT_DIR) {
    die $usage;
}


if (@ARGV) {
    die "Error, dont understand params: @ARGV";
}


unless ($ENV{TRINITY_HOME}) {
    $ENV{TRINITY_HOME} = "$FindBin::Bin/../../trinityrnaseq/";
}


main: {
    
    my $BASEDIR = cwd();
    
    unless ($ref_trans_fa =~ /^\//) {
        $ref_trans_fa = "$BASEDIR/$ref_trans_fa";
    }
            
            
    unless (-d $OUT_DIR) {
        &process_cmd("mkdir -p $OUT_DIR");
    }
    chdir $OUT_DIR or die "Error, cannot cd to $OUT_DIR";
    

    my $cmd = "";
    
    if ($use_wgsim_flag) {
        
        # simulate reads:
        $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.wgsim.pl --transcripts $ref_trans_fa "
            . " --read_length $READ_LENGTH "
            . " --frag_length $FRAG_LENGTH "
            . " --depth_of_cov 200 "
            ;
        
        if ($strand_specific_flag) {
            $cmd .= " --SS_lib_type FR ";
        }

        ## todo: add mutation rate info
        
    }
    else {
        
        # default, use home-grown simple simulator
        
        # simulate reads:
        $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.pl --transcripts $ref_trans_fa --include_volcano_spread "
            . " --require_proper_pairs "
            . " --read_length $READ_LENGTH "
            . " --frag_length $FRAG_LENGTH "
            . " --max_depth 4 --frag_length_step 200 "
            ;
        
        if ($READ_MUT_RATE) {
            $cmd .= " --error_rate $READ_MUT_RATE ";
        }
    }
    
    &process_cmd($cmd);

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

