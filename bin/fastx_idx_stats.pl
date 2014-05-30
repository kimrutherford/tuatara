#!/usr/bin/env perl

use perl5i::2;
use Moose;
use Bio::SeqIO;
use Bio::Seq::Quality;

my $file = shift;

if (!defined $file) {
  die "$0: needs a FASTQ/A file arg\n";
}

my $in_format;
my $out_fasta = undef;
my $fasta_file;

if ($file =~ /(.+)\.(fastq|fq)$/i) {
  $in_format = 'fastq';

  $fasta_file = "$1.fasta";

  $out_fasta = Bio::SeqIO->new(-format => 'fasta', -file => ">$fasta_file");
} else {
  $in_format = 'fasta';
  $fasta_file = $file;
}

my $seqio  = Bio::SeqIO->new(-format => $in_format , -file => $file);

my $count = 0;

while(my $rec = $seqio->next_seq()) {
  if ($in_format eq 'fastq') {
    $out_fasta->write_seq($rec);
  }

  $count++;
}

my $stats_file_name = "$fasta_file.stats";
open my $stats_fh, '>', $stats_file_name or die "can't open $stats_file_name\n";

print $stats_fh "stats for $fasta_file\n\nread_count: $count\n\n";

close $stats_fh;


my $count_file_name = "$fasta_file.count";
open my $count_fh, '>', $count_file_name or die "can't open $count_file_name\n";

print $count_fh "$count\n";

close $count_fh;

if ($in_format eq 'fasta') {
  system "fastaindex -f $fasta_file -i $fasta_file.fastaindex";
  system "abyss-fac $fasta_file >> $fasta_file.stats";
}
