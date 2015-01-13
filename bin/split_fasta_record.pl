#!/usr/bin/env perl

# split a record in a fasta file at a given base and record_ID
# the new fragments are named record_ID-a and record_ID-b

use warnings;
use strict;

use Bio::SeqIO;

my $split_id = shift;
my $split_pos = shift;

if (!defined $split_pos) {
  die "usage: $0 fasta_record_ID base_position < fasta_file

splits the given record in the input after the given base_position
";
}

if ($split_pos < 1) {
  die "can't split after $split_pos - too small\n";
}

my $seqout = Bio::SeqIO->new(-fh => \*STDOUT, -format => 'Fasta');

my $seqin = Bio::SeqIO->new(-fh => \*STDIN, -format => 'fasta');

while(my $rec = $seqin->next_seq()) {
  my $id = $rec->id();
  my $seq = $rec->seq();

  if ($id eq $split_id) {
    if ((length $seq) - 1< $split_pos) {
      die "$id is too short (", length $seq, ") to split at $split_pos\n";
    }

    my $seq_a = substr $seq, 0, $split_pos;
    my $seq_b = substr $seq, $split_pos;
    my $seq_obj_a = Bio::Seq->new(-seq => $seq_a,
                                  -display_id => "$id-a",
                                  -alphabet => "dna" );
    $seqout->write_seq($seq_obj_a);
    my $seq_obj_b = Bio::Seq->new(-seq => $seq_b,
                                  -display_id => "$id-b",
                                  -alphabet => "dna" );
    $seqout->write_seq($seq_obj_b);
  } else {
    $seqout->write_seq($rec);
  }
}
