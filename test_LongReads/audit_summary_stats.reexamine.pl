#!/usr/bin/env perl

use strict;
use warnings;
use File::Basename;

use lib ($ENV{EUK_MODULES});
use Fasta_reader;

my $usage = "\n\n\tusage: $0 < list of audit.txt files from stdin \n\n\n";

my $MIN_SEQ_LEN = 1000;


while (<>) {
    chomp;
    my $dir = basedir($_);
    
    my $trin_fasta_file = "$dir/trinity_out_dir.Trinity.fasta";
    
    my $fasta_reader = new Fasta_reader($trin_fasta_file);
    my %trin_seqs = $fasta_reader->retrieve_all_seqs_hash();
    
    my %trin_lens = &get_seq_lens(%trin_seqs);

    my $FL_reco_file = "$dir/FL.test.pslx.maps";
    my %reco = &parse_reco($FL_reco_file);

    

}

####
sub parse_reco {
    my ($reco_file) = @_;

    my %trin_to_reco_acc;
    
    open (my $fh, $reco_file) or die $!;
    while (<$fh>) {
        chomp;
        my ($trans_acc, $trinity_contig) = split(/\t/);
        
        $trin_to_reco_acc{$trinity_contig} = $trans_acc;
    }
    close $fh;
    
    return(%trin_to_reco_acc);
    
}


####
sub get_seq_lens {
    my (%trin_seqs) = @_;

    my %lens;

    foreach my $acc (keys %trin_seqs) {
        my $seq = $trin_seqs{$acc};
        my $seqlen = length($seq);
        
        $lens{$acc} = $seqlen;
    }

    return(%lens);

}
    
