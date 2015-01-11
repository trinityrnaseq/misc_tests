#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;

my $usage = "usage: $0 gmap.gff3 [gene-to-trans-mapping.txt]\n\n";


my $gmap_gff3_file = $ARGV[0] or die $usage;
my $gene_to_trans_file = $ARGV[1] or die $usage;

main: {

    my %trans_to_gene;
    if ($gene_to_trans_file) {
        open (my $fh, $gene_to_trans_file) or die "Error, cannot open file $gene_to_trans_file";
        while (<$fh>) {
            chomp;
            my ($gene, $trans) = split(/\t/);
            $trans_to_gene{$trans} = $gene;
        }
        close $fh;
        
        #print Dumper(\%trans_to_gene);
        
    }
    

    my %target_to_aligns;

    open (my $fh, $gmap_gff3_file) or die $!;
    while (<$fh>) {
        chomp;
        my ($hit_acc, $filename, $type, $lend, $rend, $per_id, $orient, $dot, $info) = split(/\t/);

        my %info_hash;
        foreach my $keyval (split(/;/, $info)) {
            my ($key, $val) = split(/=/, $keyval);
            $info_hash{$key} = $val;
        }
        
        my ($target, $range_lend, $range_rend) = split(/\s+/, $info_hash{Target});

        push (@{$target_to_aligns{$target}}, { hit => $hit_acc,
                                               lend => $lend,
                                               rend => $rend,
                                               orient => $orient,
                                               per_id => $per_id,
                                               
                                               range_lend => $range_lend,
                                               range_rend => $range_rend,
              });

    }
    close $fh;

    foreach my $target (keys %target_to_aligns) {
        
        my %target_got;

        my $target_name = $target;
        if (%trans_to_gene) {
            if ($target =~ /^(\S+)--(\S+)/) {
                my $transA = $1;
                my $transB = $2;
                my $geneA = $trans_to_gene{$transA} or die "Error, no gene for trans: $transA of $target";
                my $geneB = $trans_to_gene{$transB} or die "Error, no gene for trans: $transB of $target";
                $target_name = "$geneA--$geneB";
            
                $target_got{$geneA} = -1;
                $target_got{$geneB} = -1;
            }
        }
        my $align_text = "$target_name";

        my @aligns = @{$target_to_aligns{$target}};

        @aligns = sort {$a->{range_lend}<=>$b->{range_lend}} @aligns;

        my $num_aligns = scalar @aligns;
        $align_text .= "\t$num_aligns";
        
        foreach my $align (@aligns) {
            my $hit = $align->{hit};
            
            if (%trans_to_gene) {
                my $gene = $trans_to_gene{$hit} or die "Error, no gene for trans: $hit";
                $hit = $gene;
                
                if (exists $target_got{$hit}) {
                    $target_got{$hit} = 1;
                }
            }
            
            my $range_lend = $align->{range_lend};
            my $range_rend = $align->{range_rend};
            my $orient = $align->{orient};
            my $per_id = $align->{per_id};


            $align_text .= "\t[$hit:$range_lend-$range_rend ($orient) $per_id\%]";
        }
        if (%target_got) {

            my @accs = keys %target_got;
            foreach my $acc (@accs) {
                if ($target_got{$acc} > 0) {
                    delete($target_got{$acc});
                }
            }
            if (%target_got) {
                $align_text = "NO\t$align_text";
            }
            else {
                $align_text = "YES\t$align_text";
            }
        }
        

        print $align_text . "\n";
    }


    exit(0);
}
