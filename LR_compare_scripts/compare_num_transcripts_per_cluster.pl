#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $output_prefix = 'cluster_count_comparison';

my $usage = <<__EOUSAGE__;

#############################################################################
#
# Required:
#
#  --trinA_fasta <string>       Trinity fasta file
#
#  --trinB_fasta <string>       Trinity fasta file
#
# Optional:
#
#  --out_prefix <string>        output prefix (default: $output_prefix )
#
#  --require_LR                 only compare clusters containing LR support
#
#  --min_trans_len <int>        minimum transcript length to be counted
#
############################################################################ 

__EOUSAGE__

    ;


my $help_flag;

my $fileA_fasta;
my $fileB_fasta;
my $require_LR_cluster;
my $min_trans_len = 0;




&GetOptions ( 'h' => \$help_flag,
              'trinA_fasta=s' => \$fileA_fasta,
              'trinB_fasta=s' => \$fileB_fasta,
              'require_LR' => \$require_LR_cluster,
              'min_trans_len=i' => \$min_trans_len,
              'out_prefix=s' => \$output_prefix,
    );


unless ($fileA_fasta && $fileB_fasta) {
    die $usage;
}



main: {
    
    my %has_LR;
    
    my %cluster_to_asmbl_count_A = &parse_cluster_counts($fileA_fasta, \%has_LR, $min_trans_len);

    my %cluster_to_asmbl_count_B = &parse_cluster_counts($fileB_fasta, \%has_LR, $min_trans_len);
    
    my %clusters = map { + $_ => 1 } (keys %cluster_to_asmbl_count_A, keys %cluster_to_asmbl_count_B);

    my $out_dat_filename = "$output_prefix.dat";
    open (my $ofh, ">$out_dat_filename") or die "Error, cannot write to $out_dat_filename";
    
    print $ofh "A\tB\n"; # column headers
    
    foreach my $cluster (sort keys %clusters) {
        
        if ($require_LR_cluster && ! exists $has_LR{$cluster}) {
            next;
        }
        
        my $countA = $cluster_to_asmbl_count_A{$cluster} || 0;
        my $countB = $cluster_to_asmbl_count_B{$cluster} || 0;
        
        print $ofh join("\t", $cluster, $countA, $countB) . "\n";
    }
    close $ofh;

    # plot it:
    {
        my $Rscript = "$output_prefix.dat.Rscript";
        my $pdf_filename = "$output_prefix.dat.pdf";
        open ($ofh, ">$Rscript") or die "Error, cannot write to $Rscript";
        print $ofh "data = read.table(\"$out_dat_filename\")\n"
            .      "pdf(\"$pdf_filename\")\n"
            .      "data = data[data[,1] != data[,2], ]\n"
            .      "plot(data[,2], data[,1])\n"
            .      "abline(a=0,b=1, col='green')\n"
            .      "deltas = data[,2] - data[,1]\n"
            .      "hist(deltas)\n"
            .      "deltas[deltas<0] = -1\n"
            .      "deltas[deltas>0] = 1\n"
            .      "hist(deltas)\n"
            .      "dev.off()\n";
        close $ofh;
        
        system("Rscript $Rscript");
    }
    
    

    exit(0);
    
}


####
sub parse_cluster_counts {
    my ($file, $has_LR_href, $min_trans_len) = @_;

    my %cluster_to_counts;

    open(my $fh, $file) or die "Error, cannot open file $file";
    while (<$fh>) {
        if (/^>(\S+)/) {
            my $line = $_;
            
            my $acc = $1;

            my @pts = split(/_/, $acc);
            
            my $cluster = $pts[1];
            
            $line =~ /len=(\d+)/;
            my $length = $1;
            if ($min_trans_len && $length < $min_trans_len) { 
                next; 
            }
            
            
            $cluster_to_counts{$cluster}++;
            
            if ($has_LR_href && $line =~ /LR\$/) {
                $has_LR_href->{$cluster}++;
            }
            
        }
    }
    close $fh;

    return(%cluster_to_counts);

}
            
