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
my $BFLY_JAR;
my $MIN_REFSEQ_LENGTH = 100;
my $INCLUDE_REF_TRANS = 0;
my $OUT_DIR = "testing_dir";


my $usage = <<__EOUSAGE__;

################################################################################
#
#  * Required:
#
#  --ref_trans|R <string>                 reference transcriptome
#
#  --bfly_jar|B <string>                  Butterfly jar file
#
#  * Common Opts:
#
#  --by_Gene                              target all isoforms of a gene at once.
#
#  --num_failures_capture|N <int>         number of failed perfect reconstructions to 
#                                       capture. (default: $NUM_FAILURES_TO_CAPTURE)
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
#  * clean-up options:
#
#  --no_purge                           keep files around for correctly reconstructed entries.
#                                       (default: only the non-FL reconstructed ones are retained)
#
#  --always_purge                       always purge work directories
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
#  --shuffle                            tackle transcripts in random order (default lexographically)
#
#  --max_isoforms <int>                 max number of isoforms to test
#
#  --strict                             weld all, no pruning or path merging.
#
#  --max_iter <int>                     max number of iterations (default: 0) // turned off
##
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

my $BY_GENE_FLAG = 0;

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
              'num_failures_capture|N=i' => \$NUM_FAILURES_TO_CAPTURE,
              'min_refseq_length=i' => \$MIN_REFSEQ_LENGTH,
              'incl_ref_trans_itself' => \$INCLUDE_REF_TRANS,
              
              'ref_trans_only' => \$REF_TRANS_ONLY,
              
              'no_purge' => \$NO_PURGE_FLAG,
              'always_purge' => \$ALWAYS_PURGE_FLAG,
              
              'strict' => \$STRICT,

              'V=i' => \$VERBOSITY_LEVEL,
    
              'by_Gene' => \$BY_GENE_FLAG,

              'acc=s' => \$RESTRICT_TO_ACC,
              
              'incl_ref_dot' => \$INCLUDE_REF_DOT_FILES,

              'paired_as_single' => \$PAIRED_AS_SINGLE,
              
              'shuffle' => \$SHUFFLE,

              'max_isoforms=i' => \$MAX_ISOFORMS,
	      
	      'read_mut_rate=f' => \$READ_MUT_RATE,

	      'ref_mut_indel_rate=f' => \$REF_MUT_INDEL_RATE,
	      'ref_mut_subst_rate=f' => \$REF_MUT_SUBST_RATE,
	      
	      'max_iter=i' => \$MAX_ITER,
	      
	      

);


if ($help_flag) {
    die $usage;
}



unless ($ref_trans_fa && $BFLY_JAR) {
    die $usage;
}


unless ($ENV{TRINITY_HOME}) {
    $ENV{TRINITY_HOME} = "$FindBin::Bin/../../trunk/";
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
    

    open (my $ofh, ">$reconstructions_log_file") or die "Error, cannot write to $reconstructions_log_file";
    
    if ($ref_trans_fa =~ /\.gz$/) {
        my $unzipped = $ref_trans_fa;
        $unzipped =~ s/\.gz$//g;
        if (! -s $unzipped) {
            &process_cmd("gunzip -c $ref_trans_fa > $unzipped");
        }

        $ref_trans_fa = $unzipped;
    }
    
    my $fasta_reader = new Fasta_reader($ref_trans_fa);
    my %fasta_seqs = $fasta_reader->retrieve_all_seqs_hash();

    my %reorganized_fasta_seqs = &reorganize_fasta_seqs(\%fasta_seqs, $BY_GENE_FLAG, $RESTRICT_TO_ACC);

        
    unless (-d $OUT_DIR) {
        mkdir($OUT_DIR) or die $!;
    }
    
        
    my $total_counter = 0;
    my $failed_counter = 0;

    my @accs = keys %reorganized_fasta_seqs;

    if ($SHUFFLE) {
        @accs = shuffle(@accs);
    }
    else {
        @accs = sort(@accs);
    }

    foreach my $acc (@accs) {
        
        chdir $BASEDIR or die "Error, cannot cd to $BASEDIR";
        
            
        my $seq_entries_aref = $reorganized_fasta_seqs{$acc};
        
        my @min_length_targets;
        foreach my $entry (@$seq_entries_aref) {
            print Dumper($entry);
            
            my ($trans_acc, $seq) = @$entry;
            if (length($seq) >= $MIN_REFSEQ_LENGTH) {
                push (@min_length_targets, $entry);
            }
        }
        
        unless (@min_length_targets) { 
            print STDERR "No min length targets to pursue for $acc .... skipping.\n";
            next; 
        }
        

        my $num_total_targets = scalar(@min_length_targets);
        
        if ($BY_GENE_FLAG && $num_total_targets < 2) {
            next;
        }

        
        my $num_FL = 0;
        my $num_contigs = 0;
        
        $total_counter++;
        

        eval {
            ($num_FL, $num_contigs) = &execute_seq_pipe($acc, \@min_length_targets);
        };
        if ($@) {
            $num_FL = "ERROR";
            $num_contigs = 0;
            print STDERR "$@";
        }
        
        my $captured_all_FL = "NO";
        
        if ($num_FL ne "ERROR" && $num_FL == scalar(@min_length_targets)) {
            $captured_all_FL = "YES";
        }
	else {
	    $failed_counter++;
	}
        
        print $ofh join("\t", $acc, $num_FL, $num_total_targets, $captured_all_FL, $num_contigs) . "\n"; 
        
        print STDERR "\n\n\n$acc ******* [$failed_counter/$total_counter] non-FL captured so far *********\n\n\n";
        
        if ($failed_counter >= $NUM_FAILURES_TO_CAPTURE) {
            last;
        }

	if ($MAX_ITER && $total_counter >= $MAX_ITER) {
	    print STDERR "Reached $MAX_ITER max iterations. Stopping now.\n";
	    last;
	}
                
    }
    
    close $ofh;
    
    exit(0);
}



####
sub execute_seq_pipe {
    my ($acc, $entries_aref) = @_;
    
    my $num_entries = scalar(@$entries_aref);

    my $basedir = cwd();
    
    my $dir_tok = $acc;
    $dir_tok =~ s/\W/_/g;
    
    my $workdir = "$OUT_DIR/$dir_tok";
    
    unless (-d $workdir) {
        mkdir $workdir or die "Error, cannot mkdir $workdir";
    }
    chdir $workdir or die "Error, cannot cd to $workdir";
    
    # write ref fasta seqs.
    if (! -s "refseqs.fa") {
        open (my $ofh, ">refseqs.fa") or die $!;
        foreach my $entry (@$entries_aref) {
            my ($entry_acc, $seq_acc) = @$entry;
            print $ofh ">$entry_acc\n$seq_acc\n";
        }
        close $ofh;
    }
    

    unless ($REF_TRANS_ONLY) {
        
        # simulate reads:
        my $cmd = "$ENV{TRINITY_HOME}/util/misc/simulate_illuminaPE_from_transcripts.pl --transcripts refseqs.fa --include_volcano_spread";
        if ($READ_MUT_RATE) {
	    $cmd .= " --error_rate $READ_MUT_RATE --max_depth 20 ";
	}
	
	if (! -s "reads.left.simPE.fa") {
            &process_cmd($cmd);
        }
    }
    
    
    # run Trinity
    
    my $bfly_jar_txt = "";
    if ($BFLY_JAR) {
        $bfly_jar_txt = " --bfly_jar $BFLY_JAR ";
    }
    
    my $cmd = "set -o pipefail; $ENV{TRINITY_HOME}/Trinity --seqType fa --max_memory 1G --no_cleanup ";

    if ($REF_TRANS_ONLY) {
        $cmd .= " --single refseqs.fa --SS_lib_type F ";
    }
    else {
        
        if ($INCLUDE_REF_TRANS) {
	    
            if ($REF_MUT_INDEL_RATE || $REF_MUT_SUBST_RATE) { 
		
		&process_cmd("$ENV{TRINITY_HOME}/util/misc/randomly_mutate_seqs.pl --fasta refseqs.fa --indel $REF_MUT_INDEL_RATE --subst $REF_MUT_SUBST_RATE > refseqs.mut.fa");
		
		$cmd .= " --long_reads refseqs.mut.fa ";
		
	    }
	    else {
		$cmd .= " --long_reads refseqs.fa ";
            }
        }
    
        $cmd .= " --left reads.left.simPE.fa --right reads.right.simPE.fa --SS_lib_type FR ";

    }


    $cmd .= " --CPU 2 $bfly_jar_txt --inchworm_cpu 1 --min_contig_length 100 ";
    
    my $bfly_opts = " --bfly_opts \"--generate_intermediate_dot_files -R 1 --generate_intermediate_dot_files $PAIRED_AS_SINGLE --stderr -V $VERBOSITY_LEVEL @ARGV\" ";
    
    if ($STRICT) {
        $cmd .= " --chrysalis_debug_weld_all --iworm_opts \"--no_prune_error_kmers --min_assembly_coverage 1  --min_seed_entropy 0 --min_seed_coverage 1 \" ";  
        
        $bfly_opts = " --bfly_opts \"--dont-collapse-snps --no_pruning --no_path_merging --no_remove_lower_ranked_paths --MAX_READ_SEQ_DIVERGENCE=0 --NO_DP_READ_TO_VERTEX_ALIGN --generate_intermediate_dot_files -R 1 --generate_intermediate_dot_files $PAIRED_AS_SINGLE --stderr -V $VERBOSITY_LEVEL @ARGV\" ";
        
    }
    
    $cmd .= " $bfly_opts 2>&1 | tee trin.log";
    

    {
        open (my $ofh, ">runTrinity.cmd") or die $!;
        print $ofh $cmd;
        close $ofh;
    }
    if (! -s "trinity_out_dir/Trinity.fasta") {
        &process_cmd($cmd);
    }


    if ($INCLUDE_REF_DOT_FILES) {
        # generate sequence graphs just refseqs
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa --graph refseqs.dot";
        if (! -s "refseqs.dot") {
            &process_cmd($cmd);
        }
        
        # generate sequence graphs just refseqs
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa,trinity_out_dir/inchworm.K25.L25.fa --graph refseqs_w_iworm.dot";
        if (! -s "refseqs_w_iworm.dot") {
            &process_cmd($cmd);
        }
        
        # generate sequence graphs combining all
        $cmd = "$ENV{TRINITY_HOME}/util/misc/Monarch --misc_seqs refseqs.fa,trinity_out_dir/inchworm.K25.L25.fa,trinity_out_dir/Trinity.fasta --graph all_compare.dot";
        if (! -s "all_compare.dot") {
            &process_cmd($cmd);
        }
    }

    
    # compare refseqs to the trinity assemblies
    $cmd = "$ENV{TRINITY_HOME}/util/misc/illustrate_ref_comparison.pl refseqs.fa trinity_out_dir/Trinity.fasta 98 | tee ref_compare.ascii_illus";
    if (! -s "ref_compare.ascii_illus") {
        &process_cmd($cmd);
    }
    else {
        &process_cmd("cat ref_compare.ascii_illus");
    }

    ## get number of transcripts reconstructed:
    $cmd = "grep '>' trinity_out_dir/Trinity.fasta | wc -l";
    my $result = `$cmd`;
    $result =~ s/^\s+//g;
    my ($num_transcripts, @rest) = split(/\s+/, $result);
    

    
    # reconstruction test
    $cmd = "$ENV{TRINITY_HOME}/Analysis/FL_reconstruction_analysis/FL_trans_analysis_pipeline.pl --target refseqs.fa --query trinity_out_dir/Trinity.fasta --reuse --out_prefix FL.test  --allow_non_unique_mappings | tee FL_analysis.txt";

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
        
    
    chdir $basedir or die "Error, cannot cd back to $basedir";


    my $got_all_flag = 0;
    
    if ($num_FL == $num_entries) {
        print STDERR "-got all FL ($num_FL reconstructed / $num_entries total reconstructed).\n";
    
        $got_all_flag = 1;
        #print STDERR Dumper(\@pts);
    }
    else {
        print STDERR "** missed at least one reconstructed isoform ($num_FL reconstructed / $num_entries total reconstructed).\n";
    }
    

    unless($NO_PURGE_FLAG) {
        if ($got_all_flag || $ALWAYS_PURGE_FLAG) {
            &process_cmd("rm -rf $workdir");
        }
    }
    
    
    return ($num_FL, $num_transcripts);

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
    
####
sub reorganize_fasta_seqs {
    my ($fasta_seqs_href, $by_gene_flag, $restrict_to_acc) = @_;

    my %reorg_fasta;

    foreach my $acc (sort keys %$fasta_seqs_href) {
        
        my $seq = uc $fasta_seqs_href->{$acc};

        my $key = $acc;
        if ($by_gene_flag) {
            my ($trans, $gene) = split(/;/, $acc);
            unless ($gene) {
                confess "Error, no gene ID extracted from $acc ";
            }
            $key = $gene;
        }

        if ($restrict_to_acc && ($key ne $restrict_to_acc)) {
            next;
        }
                
        if ($MAX_ISOFORMS > 1 && exists $reorg_fasta{$key}) {
            
            if (scalar(@{$reorg_fasta{$key}} >= $MAX_ISOFORMS)) {
                next;
            }
        }
        
        push (@{$reorg_fasta{$key}}, [$acc, $seq]);
    }

    return(%reorg_fasta);
    
}

