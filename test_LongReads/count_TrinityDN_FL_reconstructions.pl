#!/usr/bin/env perl

use strict;
use warnings;

use lib($ENV{EUK_MODULES});
use DelimParser;
use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);


my $min_per_id = 99;
my $max_per_gap = 1;
my $min_per_length = 99;

my $usage = <<__EOUSAGE__;

#################################################################
#
# Required:
#
#  --psl_stats <string>        psl_stats input file
#
#  --ref_trans <string>        reference transcript fasta file
#                            
#  --gene_trans_map <string>   gene-trans-map file
#
# Optional:
#
#  --min_per_id <int>          min percent identity (default: $min_per_id)
#
#  --max_per_gap <int>         max percent gap (default: $max_per_gap)
#
#  --min_per_len <int>         min percent of target transcript length matched ($min_per_length)
#
#  --strand_specific           allow only '+' alignments
#
################################################################

__EOUSAGE__

    ;


my $help_flag;
my $psl_stats_file;
my $ref_trans_file;
my $gene_trans_map_file;
my $strand_specific_flag = 0;

&GetOptions ( 'h' => \$help_flag,

              'psl_stats=s' => \$psl_stats_file,
              'ref_trans=s' => \$ref_trans_file,
              'gene_trans_map=s' => \$gene_trans_map_file,

              'min_per_id=i' => \$min_per_id,
              'max_per_gap=i' => \$max_per_gap,
              'min_per_len=i' => \$min_per_length,

              'strand_specific' => \$strand_specific_flag,
    );

if ($help_flag) {
    die $usage;
}

unless($psl_stats_file && $ref_trans && $gene_trans_map) {
    die $usage;
}


main: {
    
    my %trans_to_gene; 
    my %gene_to_trans;
    &parse_gene_trans_map($gene_trans_map_file, \%trans_to_gene, \%gene_to_trans);
    
    open(my $fh, $psl_stats_file) or die "Error, cannot open file $psl_stats_file";
    my $tab_reader = new DelimParser::Reader($fh, "\t");
    

    

    ## count transcripts and genes.
    my %query_seen;
        
    while (my $row = $tab_reader->get_row()) {
        
        my ($target, $query, $per_id, $per_gap, $score, $strand, $per_len) = (
            $row->{target}, $row->{query}, $row->{per_id}, $row->{per_gap},
            $row->{score}, $row->{strand}, $row->{per_len} );

        $query_seen{$query} = 1;
        
        if ($strand_specific_flag && $strand ne '+') {
            continue;
        }

        if ($per_id >= $min_per_id
            &&
            $per_gap <= $max_per_gap
            &&
            $per_len >= $min_per_len) {

            # got candidate 'full-length' match.

            my $gene = $trans_to_gene{$target} or die "Error, cannot find gene for trans: $target";
            $gene_to_trans{$gene}->{$target} = 1;
            
            
        }
                
    }

    ## count up results:
    
    my $num_ref_genes = 0;
    my $num_ref_trans = 0;
    my $num_FL = 0;
    my $num_total_trans = scalar(keys %query_seen);
    my $num_total_genes = scalar(keys %gene_to_trans);

    my $num_genes_all_yes = 0;
    
    foreach my $gene (keys %gene_to_trans) {
        my $trans_href = $gene_to_trans{$gene};

        $num_ref_genes++;
        my $reconstructed_all_iso_flag = 1;
        foreach my $trans (keys %$trans_href) {
            $num_ref_trans++;
                        
            if ($trans_href->{$trans}) {
                $num_FL++;
            }
            else {
                $reconstructed_all_iso_flag = 0;
            }
        }
        if ($reconstructed_all_iso_flag) {
            $num_genes_all_yes++;
        }
    }

    my $num_additional = $num_total_trans - $num_FL;
    my $num_genes_all_no = $num_total_genes - $num_genes_all_yes;
    
    print join("\t", "#all_genes_yes", "all_genes_no", "num_FL_trans", "num_total_trans", "num_additional_trans") . "\n";
    print join("\t", $num_genes_all_yes, $num_genes_all_no, $num_FL, $num_total_trans, $num_additional) . "\n";
    
    exit(0);
    
}

####
sub parse_gene_trans_map {
    my ($file, $trans_to_gene_href, $gene_to_trans_href) = @_;

    my %trans_to_gene;
    
    open (my $fh, $file) or die "Error, cannot read file: $file";
    while (<$fh>) {
        chomp;
        my ($gene, $trans) = split(/\t/);
        
        $trans_to_gene_href->{$trans} = $gene;

        $gene_to_trans_href->{$gene}->{$trans} = 0;
    }
    close $fh;
    
    return;
}

