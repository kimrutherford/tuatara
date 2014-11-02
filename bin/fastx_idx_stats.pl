#!/usr/bin/env perl

use perl5i::2;
use Moose;
use Getopt::Long;
use Digest::MD5;

use Bio::SeqIO;
use Bio::Seq::Quality;

my $do_sums = 0;
my $do_help = 0;

my $result = GetOptions ("sums|s" => \$do_sums,
                         "help|h" => \$do_help);

sub help
{
  die "usage:\n  $0 [--sums|-s] file\n";
}

if (!$result || $do_help) {
  usage();
}

my $file = shift;

if (!defined $file) {
  die "$0: needs a FASTQ/A file arg\n";
}

my $in_format;
my $out_fasta = undef;
my $fasta_file;

if ($file =~ /(.+)\.(fastq|fq)(?:\.gz)?$/i) {
  $in_format = 'fastq';

  $fasta_file = "$1.fasta";

  if (-f $fasta_file && (stat $fasta_file)[9] >= (stat $file)[9]) {
    # skip output fasta
  } else {
    $out_fasta = Bio::SeqIO->new(-format => 'fasta', -file => ">$fasta_file");
  }
} else {
  $in_format = 'fasta';
  $fasta_file = $file;
}

warn "reading $file, input format $in_format\n";

if ($in_format eq 'fastq' && !defined $out_fasta) {
  warn "$fasta_file exists - not writing\n";
}

my $sums_file_name = "$fasta_file.seq_sums";
my $sums_fh = undef;
if ($do_sums) {
  if (-f $sums_file_name) {
    warn "$sums_file_name exists - not writing\n";
  } else {
    open $sums_fh, '>', $sums_file_name or die "can't open $sums_file_name\n";
  }
}

my $stats_file_name = "$fasta_file.stats";

my $file_for_seqio = $file;

if ($file =~ /\.gz$/) {
  $file_for_seqio = "gzip -d < $file |";
}

my $seqio  = Bio::SeqIO->new(-format => $in_format , -file => $file_for_seqio);

my $count = 0;

if (! -f $stats_file_name || defined $out_fasta) {
  while(my $rec = $seqio->next_seq()) {
    if ($in_format eq 'fastq' && defined $out_fasta) {
      $out_fasta->write_seq($rec);
    }

    if (defined $sums_fh) {
      my $ctx = Digest::MD5->new();
      $ctx->add($rec->seq());

      print $sums_fh $rec->id(), " ", $ctx->hexdigest(), "\n";
    }

    $count++;
  }
}

if (defined $sums_fh) {
  close $sums_fh or die "can't close $sums_file_name\n";
}

if (-f $stats_file_name && (stat $stats_file_name)[9] >= (stat $file)[9]) {
  warn "$stats_file_name exists - not writing\n";
} else {
  open my $stats_fh, '>', $stats_file_name or die "can't open $stats_file_name\n";
  print $stats_fh "stats for $fasta_file\n\nseq_count: $count\n\n";
  close $stats_fh;

  if ($in_format eq 'fasta') {
    system "abyss-fac $fasta_file >> $stats_file_name";
  }
}

my $count_file_name = "$fasta_file.count";
if (-f $count_file_name && (stat $count_file_name)[9] >= (stat $file)[9]) {
  warn "$count_file_name exists - not writing\n";
} else {
  open my $count_fh, '>', $count_file_name or die "can't open $count_file_name\n";
  print $count_fh "$count\n";
  close $count_fh;
}

if ($in_format eq 'fasta') {
  my $bp_index_filename = "$fasta_file.bp_index";
  if (-f $bp_index_filename &&
      (stat $bp_index_filename)[9] >= (stat $file)[9]) {
    warn "$fasta_file.bp_index exists - not writing\n";
  } else {
    my ($dir, $file) = "$fasta_file.bp_index" =~ m|(.*)/(.*)|;

    if (!defined $dir) {
      $file = $bp_index_filename;
      $dir = '.';
    }

    system "bp_index.pl -dir $dir -fmt fasta $file $fasta_file";
  }
  if (-f "$fasta_file.fastaindex" && (stat "$fasta_file.fastaindex")[9] >= (stat $file)[9]) {
    warn "$fasta_file.fastaindex exists - not writing\n";
  } else {
    system "fastaindex -f $fasta_file -i $fasta_file.fastaindex";
  }

  if (-f "$fasta_file.names_sizes" && (stat "$fasta_file.names_sizes")[9] >= (stat $file)[9]) {
    warn "$fasta_file.names_sizes exists - not writing\n";
  } else {
    system "fastaNamesSizes.pl $fasta_file > $fasta_file.names_sizes";
  }

  if (-f "$fasta_file.assemblathon_stats" && (stat "$fasta_file.assemblathon_stats")[9] >= (stat $file)[9]) {
    warn "$fasta_file.assemblathon_stats exists - not writing\n";
  } else {
    system "assemblathon_stats.pl $fasta_file > $fasta_file.assemblathon_stats";
  }
}
