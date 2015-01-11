#!/usr/bin/env perl

use strict;
use warnings;

use FindBin;
use lib ("$FindBin::Bin/../../PerlLib/");
use EM;
use Getopt::Long qw(:config no_ignore_case bundling);


my $usage = <<__EOUSAGE__;

#################################################################################
#
#  Required:
#
#  --num_transcripts <int>
#  --total_reads <int>
#  --percent_shared <float>   
#  
#  Optional:
#
#  --simulation_count <int>    :default 100
#
#  --max_iterations <int>      :default 1000
#  --min_delta_ML <float>      :default 0.001
#
################################################################################

__EOUSAGE__

    ;


my ($num_transcripts, $total_reads, $percent_shared);

my $simulation_count = 100;
my $max_iterations = 1000;
my $min_delta_ML = 0.001;

&GetOptions( 'num_transcripts=i' => \$num_transcripts,
             'total_reads=i' => \$total_reads,
             'percent_shared=f' => \$percent_shared,
             
             'simulation_count=i' => \$simulation_count,
             'max_iterations=i' => \$max_iterations,
             'min_delta_ML=f' => \$min_delta_ML,
    );

unless ($num_transcripts && $total_reads && $percent_shared) {
    die $usage;
}


main: {

    my %seqs;
    for my $seq_count (1..$num_transcripts) {
        my $acc = "seq$seq_count";
        my $seq = 'N' x 100;
        $seqs{$acc} = $seq;
    }

    my @accs = keys %seqs;
    
    my $num_shared_reads = int( $percent_shared / 100 * $total_reads);
    my $num_unique_reads = $total_reads - $num_shared_reads;

    for my $iter (1..$simulation_count) {
        
        my $em_obj = new EM(\%seqs);
        
        ## determine relative expression levels.
        my %relative_expression_values = &compute_random_expression_levels(keys %seqs);
        
        foreach my $acc (@accs) {
            
            my $num_uniq_reads_for_acc = int($relative_expression_values{$acc} * $num_unique_reads);
            
            for (1..$num_uniq_reads_for_acc) {
                $em_obj->add_read($acc);
            }
        }

        for (1..$num_shared_reads) {
            $em_obj->add_read(@accs);
        }
                    
        
        $em_obj->run( max_iterations => $max_iterations, min_delta_ML => $min_delta_ML);
        
        $em_obj->report_results();
        
    }
    

}

####
sub compute_random_expression_levels {
    my (@trans_accs) = @_;

    my %rand_vals;
    my $sum_rand_vals = 0;
    foreach my $trans(@trans_accs) {
        my $rand_val = rand(1);
        $sum_rand_vals += $rand_val;
        $rand_vals{$trans} = $rand_val;
    }

    my %rel_expr;
    foreach my $trans (@trans_accs) {
        my $val = $rand_vals{$trans};
        $rel_expr{$trans} = $val / $sum_rand_vals;
    }

    return(%rel_expr);
}

