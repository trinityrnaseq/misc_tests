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
my $NUM_FAILURES_TO_CAPTURE = 10;
my $BFLY_JAR = "$ENV{TRINITY_HOME}/Butterfly/Butterfly.jar";
my $MIN_REFSEQ_LENGTH = 100;
my $INCLUDE_REF_TRANS = 0;
my $OUT_DIR = "testing_dir";
my $READ_LENGTH = 76;
my $FRAG_LENGTH = 300;
my $MIN_CONTIG_LENGTH = 200;

my $usage = <<__EOUSAGE__;

################################################################################
#
#  * Required:
#
#  --ref_trans|R <string>                 reference transcriptome
#
#  * Common Opts:
#
#  --bfly_jar|B <string>                  Butterfly jar file
#
#  --read_length <int>                    read length (defalt: $READ_LENGTH)
#
#  --frag_length <int>                    fragment length (default: $FRAG_LENGTH)
#
#  --out_dir|O <string>                   output directory name (default: $OUT_DIR)
#
#  * include FL seq opts:
#
#  --incl_ref_trans                     include the ref transcript as a long 
#                                       read (default: off)
#
#  --ref_trans_only                     only target the ref transcript itself
#                                       (no simulation of short reads)
#
#  * Misc Opts:
#
#  --min_refseq_length <int>            min length for a reference transcript 
#                                       sequence (default: $MIN_REFSEQ_LENGTH)
#
#  --incl_ref_dot                       include dot files for the reference sequences
#
#  -V <int>                             verbosity level (default: 12)
#
#  --acc <string>                       restrict to a specific accession (gene or transcript)
#
#  --paired_as_single                   treat paired reads as single reads
#
#  --min_contig_length <int>            minimum contig length for Trinity assembly. default: $MIN_CONTIG_LENGTH
#
#  --strict                             weld all, no pruning or path merging.
#
####
#  ** Mutate the reads
#
#  --read_mut_rate <float>              simulated read error rate (default: 0)  (value between 0 and 0.25 allowed)
#
#  --ref_mut_indel_rate <float>         mutate indels in the ref sequence (default: 0) ( values allowed 0<x<0.25)
#
#  --ref_mut_subst_rate <float>         mutate substitutions in ref seq (default: 0) (values allowed 0<x<0.25)
#
############################################################################################


__EOUSAGE__

    ;


my $VERBOSITY_LEVEL = 12;

my $REF_TRANS_ONLY = 0;

my $NO_PURGE_FLAG = 0;
my $ALWAYS_PURGE_FLAG = 0;

my $RESTRICT_TO_ACC = "";

my $INCLUDE_REF_DOT_FILES = 0;

my $PAIRED_AS_SINGLE = "";

my $SHUFFLE = 0;

my $MAX_ISOFORMS = -1;

my $READ_MUT_RATE = 0;

my $REF_MUT_INDEL_RATE = 0;
my $REF_MUT_SUBST_RATE = 0;

my $STRICT = 0;

my $MAX_ITER = 0;


&GetOptions ( 'h' => \$help_flag,

              # required
              'ref_trans|R=s' => \$ref_trans_fa,
              
              # optional
              'out_dir|O=s' => \$OUT_DIR,
              'bfly_jar|B=s' => \$BFLY_JAR,

              'min_refseq_length=i' => \$MIN_REFSEQ_LENGTH,
              'incl_ref_trans_itself' => \$INCLUDE_REF_TRANS,
              
              'ref_trans_only' => \$REF_TRANS_ONLY,
              
              'no_purge' => \$NO_PURGE_FLAG,
              'always_purge' => \$ALWAYS_PURGE_FLAG,
              
              'strict' => \$STRICT,

              'V=i' => \$VERBOSITY_LEVEL,
    
              'incl_ref_dot' => \$INCLUDE_REF_DOT_FILES,

              'paired_as_single' => \$PAIRED_AS_SINGLE,
              
              'min_contig_length=i' => \$MIN_CONTIG_LENGTH,
              
              'read_length=i' => \$READ_LENGTH,
              'frag_length=i' => \$FRAG_LENGTH,
              
              'read_mut_rate=f' => \$READ_MUT_RATE,
              
              'ref_mut_indel_rate=f' => \$REF_MUT_INDEL_RATE,
              'ref_mut_subst_rate=f' => \$REF_MUT_SUBST_RATE,
              
                            

);


if ($help_flag) {
    die $usage;
}



unless ($ref_trans_fa && $BFLY_JAR) {
    die $usage;
}


unless ($ENV{TRINITY_HOME}) {
    $ENV{TRINITY_HOME} = "$FindBin::Bin/../../trinityrnaseq/";
}

my $reconstructions_log_file = "$OUT_DIR.reconstruction_summary.txt";


if ($PAIRED_AS_SINGLE) {
    $PAIRED_AS_SINGLE = "--TREAT_PAIRS_AS_SINGLE";
}

if ( ($REF_MUT_INDEL_RATE || $REF_MUT_SUBST_RATE) && ! $INCLUDE_REF_TRANS) {
    die "Error, ref mut rate set, but not including ref trans in reconstruction.  Use --incl_ref_trans";
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
    


    my ($num_FL, $num_entries, $num_transcripts) = &execute_seq_pipe($ref_trans_fa);
    # num_FL: number of transcripts reconstructed as full-length
    # num_entries: number of reference isoforms
    # num_transcripts: total number of Trinity transcripts reconstructed.
    
    open (my $ofh, ">audit.txt") or die $!;
    my $captured_all = ($num_FL == $num_entries) ? "YES" : "NO";
    my $summary = join("\t", $ref_trans_fa, "num_ref:", $num_entries, "num_FL:", $num_FL, "num_reco:", $num_transcripts, $captured_all) . "\n";
    print $ofh $summary;
    print $summary;
    close $ofh;
    
    exit(0);
}



####
sub execute_seq_pipe {
    my ($ref_trans_fa, $workdir) = @_;
    
            
    my $num_entries = `grep '>' $ref_trans_fa | wc -l `;
    chomp $num_entries;
    
    unless ($REF_TRANS_ONLY) {
        
        # simulate reads:
        my $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.pl --transcripts $ref_trans_fa --include_volcano_spread "
            . " --require_proper_pairs "
            . " --read_length $READ_LENGTH "
            . " --frag_length $FRAG_LENGTH "
            ;
        
        if ($READ_MUT_RATE) {
            $cmd .= " --error_rate $READ_MUT_RATE --max_depth 20 ";
        }
        
        &process_cmd($cmd);
        
    }
    
    
    # run Trinity
    
    my $bfly_jar_txt = "";
    if ($BFLY_JAR) {
        $bfly_jar_txt = " --bfly_jar $BFLY_JAR ";
    }
    
    my $cmd = "set -o pipefail; $ENV{TRINITY_HOME}/Trinity --seqType fa --max_memory 1G --full_cleanup ";

    if ($REF_TRANS_ONLY) {
        $cmd .= " --single $ref_trans_fa --SS_lib_type F ";
    }
    else {
        
        if ($INCLUDE_REF_TRANS) {
	    
            if ($REF_MUT_INDEL_RATE || $REF_MUT_SUBST_RATE) { 
                
                &process_cmd("$ENV{TRINITY_HOME}/util/misc/randomly_mutate_seqs.pl --fasta $ref_trans_fa --indel $REF_MUT_INDEL_RATE --subst $REF_MUT_SUBST_RATE > refseqs.mut.fa");
                
                $cmd .= " --long_reads refseqs.mut.fa ";
                
            }
            else {
                $cmd .= " --long_reads $ref_trans_fa ";
            }
        }
        
        $cmd .= " --left reads.left.simPE.fa --right reads.right.simPE.fa --SS_lib_type FR ";

    }
    
    $cmd .= " --CPU 2 $bfly_jar_txt --inchworm_cpu 1 --min_contig_length $MIN_CONTIG_LENGTH --trinity_complete ";
    
    my $bfly_opts = " --bfly_opts \"--generate_intermediate_dot_files -R 1 --generate_intermediate_dot_files $PAIRED_AS_SINGLE --stderr -V $VERBOSITY_LEVEL @ARGV\" ";
    
    if ($STRICT) {
        $cmd .= " --no_bowtie --chrysalis_debug_weld_all --iworm_opts \"--no_prune_error_kmers --min_assembly_coverage 1  --min_seed_entropy 0 --min_seed_coverage 1 \" ";  
        
        $bfly_opts = " --bfly_opts \"--dont-collapse-snps --no_pruning --no_path_merging --no_remove_lower_ranked_paths --MAX_READ_SEQ_DIVERGENCE=0 --NO_DP_READ_TO_VERTEX_ALIGN --generate_intermediate_dot_files -R 1 -F 100000 --generate_intermediate_dot_files $PAIRED_AS_SINGLE --stderr -V $VERBOSITY_LEVEL @ARGV\" ";
        
    }
    
    $cmd .= " $bfly_opts 2>&1 | tee trin.log";
    

    {
        open (my $ofh, ">runTrinity.cmd") or die $!;
        print $ofh $cmd;
        close $ofh;
    }
    if (! -s "trinity_out_dir.Trinity.fasta") {
        &process_cmd($cmd);
    }


    if ($INCLUDE_REF_DOT_FILES) {
        # generate sequence graphs just refseqs
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs $ref_trans_fa --graph refseqs.dot";
        if (! -s "refseqs.dot") {
            &process_cmd($cmd);
        }
        
        # generate sequence graphs just refseqs
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs $ref_trans_fa,trinity_out_dir/inchworm.K25.L25.fa --graph refseqs_w_iworm.dot";
        if (! -s "refseqs_w_iworm.dot") {
            &process_cmd($cmd);
        }
        
        # generate sequence graphs combining all
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs $ref_trans_fa,trinity_out_dir/inchworm.K25.L25.fa,trinity_out_dir.Trinity.fasta --graph all_compare.dot";
        if (! -s "all_compare.dot") {
            &process_cmd($cmd);
        }
    }

    
    # compare refseqs to the trinity assemblies
    $cmd = "$ENV{TRINITY_HOME}/util/misc/illustrate_ref_comparison.pl $ref_trans_fa trinity_out_dir.Trinity.fasta 98 | tee ref_compare.ascii_illus";
    if (! -s "ref_compare.ascii_illus") {
        &process_cmd($cmd);
    }
    else {
        &process_cmd("cat ref_compare.ascii_illus");
    }

    ## get number of transcripts reconstructed:
    $cmd = "grep '>' trinity_out_dir.Trinity.fasta | wc -l";
    my $result = `$cmd`;
    $result =~ s/^\s+//g;
    my ($num_transcripts, @rest) = split(/\s+/, $result);
    

    
    # reconstruction test
    $cmd = "$ENV{TRINITY_HOME}/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target $ref_trans_fa --query trinity_out_dir.Trinity.fasta --reuse --out_prefix FL.test  --allow_non_unique_mappings | tee FL_analysis.txt";

    &process_cmd("echo $cmd > FL.cmd");
    my @results = `$cmd`;
    print @results;
    
    chomp @results;
    shift @results;
    shift @results;
    $result = shift @results;
    $result =~ s/^\s+//;
    
    my @pts = split(/\s+/, $result);
    my $num_FL = $pts[2];
     

    my $got_all_flag = 0;
    
    if ($num_FL == $num_entries) {
        print STDERR "-got all FL ($num_FL reconstructed / $num_entries total reconstructed).\n";
    
        $got_all_flag = 1;
        #print STDERR Dumper(\@pts);
    }
    else {
        print STDERR "** missed at least one reconstructed isoform ($num_FL reconstructed / $num_entries total reconstructed).\n";
    }
    

    return ($num_FL, $num_entries, $num_transcripts);

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
