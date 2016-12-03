#!/usr/bin/env perl

use strict;
use warnings;

use Getopt::Long qw(:config posix_default no_ignore_case bundling pass_through);

my $output_prefix = 'cluster_counts_desc';
my $top_entries = 1000;

my $usage = <<__EOUSAGE__;

#############################################################################
#
# Usage: $0 [opts] TrinA.fasta [TrinB.fasta, ...]
#
# Optional:
#
#  --out_prefix <string>        output prefix (default: $output_prefix )
#
#  --require_LR                 only compare clusters containing LR support
#
#  --min_trans_len <int>        minimum transcript length to be counted
#
#  --top_entries <int>          default: $top_entries
#
############################################################################ 

__EOUSAGE__

    ;


my $help_flag;

my $require_LR_cluster;
my $min_trans_len = 0;




&GetOptions ( 'h' => \$help_flag,
              'require_LR' => \$require_LR_cluster,
              'min_trans_len=i' => \$min_trans_len,
              'out_prefix=s' => \$output_prefix,
              'top_entries=i' => \$top_entries,

    );


my @fasta_files = @ARGV;

unless (@fasta_files) {
    die $usage;
}


main: {
    
    my %has_LR;

    my @data;
    my %file_to_clusters;
    my %all_clusters;
    
    foreach my $fasta_file (@fasta_files) {
                
        my %cluster_to_asmbl_count = &parse_cluster_counts($fasta_file, \%has_LR, $min_trans_len);
        
        $file_to_clusters{$fasta_file} = \%cluster_to_asmbl_count;
        
        foreach my $cluster (keys %cluster_to_asmbl_count) {
            $all_clusters{$cluster} = 1;
        }
    }
        
    my $out_dat_filename = "$output_prefix.dat";
    open (my $ofh, ">$out_dat_filename") or die "Error, cannot write to $out_dat_filename";
    
    print $ofh join("\t", @fasta_files) . "\n"; # column headers
    
    foreach my $cluster (sort keys %all_clusters) {
        
        if ($require_LR_cluster && ! exists $has_LR{$cluster}) {
            next;
        }
    
        my @vals = ($cluster);
        foreach my $file (@fasta_files) {
            my $count = $file_to_clusters{$file}->{$cluster} || 0;
            push (@vals, $count);
        }
        print $ofh join("\t", @vals) . "\n";
        
    }
    close $ofh;

    # plot it:
    {
        my $Rscript = "$output_prefix.dat.Rscript";
        my $pdf_filename = "$output_prefix.dat.pdf";
        open ($ofh, ">$Rscript") or die "Error, cannot write to $Rscript";
        print $ofh "data = read.table(\"$out_dat_filename\")\n"
            .      "pdf(\"$pdf_filename\")\n"
            .      "s = rowSums(data)\n"
            .      "data = data[rev(order(s)),]\n"
            .      "data = data[1:$top_entries,]\n"
            .      "ptcolors = rainbow(length(colnames(data)))\n"
            .      "plot(data[,1][rev(order(data[,1]))], col=ptcolors[1], t='l')\n"
            .      "for (i in 2:length(colnames(data))) {\n"
            .      "    points(data[,i][rev(order(data[,i]))], col=ptcolors[i], t='l')\n"
            .      "}\n"
            .      "legend('topright', c(\"" . join("\",\"", @fasta_files) . "\"), col=ptcolors, pch=1)\n"
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
            
