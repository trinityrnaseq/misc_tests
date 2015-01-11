#!/usr/bin/env perl

use strict;
use warnings;

use Cwd;


main: {

    my $basedir = cwd();

    open (my $fh, "paralog_targets.txt") or die $!;
    while (<$fh>) {
        
        chdir $basedir or die "Error, cannot cd to $basedir";

        chomp;
        my ($para_A, $para_B) = split(/\s+/);
        
        my $tok = join("^^", sort($para_A, $para_B));
        my $dir = "paralog_testing/$tok";

        if (-d $dir) {
            chdir $dir or die $!;

            my $cmd = "util/illustrate_ref_comparison.pl";
            &process_cmd($cmd);
            
        }
    }
    close $fh;

    exit(0);
}



####
sub parse_align_out {
    my ($align_out_file) = @_;
    
    my @alignments;

    open (my $fh, $align_out_file) or die $!;
    while (<$fh>) {
        if (/^\#/) { next; }
        chomp;

=format
    # Fields: Query id, Subject id, % identity, alignment length, mismatches, gap openings, q. start, q. end, s. start, s. end, e-value, bit score
    comp0_c0_seq1   NM_012009_Sh2d1b1       100.00  1433    0       0       1       1433    1       1433    0.0e+00 2794.0

=cut

        my @x = split(/\t/);
        my ($trin_acc, $ref_acc, $per_id, $align_len, $mismatches, $gaps, $trin_start, $trin_end, $ref_start, $ref_end, $evalue, $bitscore) = @x;
        
        my $struct = { trin_acc => $trin_acc,
                       ref_acc => $ref_acc,
                       
                       per_id => $per_id,
                       mismatches => $mismatches,
                       gaps => $gaps,
                       
                       trin_start => $trin_start,
                       trin_end => $trin_end,

                       ref_start => $ref_start,
                       ref_end => $ref_end,

                       evalue => $evalue,
                       bitscore => $bitscore,
                   };

        push (@alignments, $struct);
    }

    return(@alignments);

}




####
sub get_seq_lengths {
    my ($refseqs_fa) = @_;

    my %lengths;
    
    open (my $fh, $refseqs_fa) or die $!;
    while (<$fh>) {
        if (/>(\S+)/) {
            my $acc = $1;
            my $seq = <$fh>;
            chomp $seq;
            my $len = length($seq);
            $lengths{$acc} = $len;
        }
    }
    close $fh;

    return(%lengths);
}
    
