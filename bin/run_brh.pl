#!/usr/bin/env perl

use strict;
use warnings;

use Bio::SeqIO;

use CHI;
use IO::All;
use IO::String;
use Cwd;

my $blast_args = shift;

my @files = @ARGV;
my $base_file = $files[0];

my %seqs = ();

for my $file (@files) {
  my $seqio = Bio::SeqIO->new(-file => $file, -format => 'Fasta');
  while (my $seq = $seqio->next_seq()) {
    $seqs{$file}->{$seq->id()} = $seq;
  }
}

sub check_blast_results
{
  my $blast_command = shift;
  my $blast_results = shift;

  my $blast_io = IO::String->new($blast_results);

  while (my $line = <$blast_io>) {
    my @bits = split /\t/, $line;

    if (@bits != 12) {
      warn "results from cache are corrupted for: $blast_command\n";
      return 0
    }
  }

  return 1;
}

my $blast_cache = CHI->new(namespace => 'blast_' . getcwd(),
                           driver => 'File', root_dir => '.');
sub blast_filter
{
  my $proc = shift;
  my $query_file = shift;
  my $db_file = shift;

  my $extra_flags = "-a 32";
  my $blast_command = "blastall $blast_args -d $db_file -i $query_file";
  my $blast_results = $blast_cache->get($blast_command);

  if (!defined $blast_results || !check_blast_results($blast_command, $blast_results)) {
    $blast_results = io("$blast_command $extra_flags|")->slurp();
    $blast_cache->set($blast_command, $blast_results);
  }

  my $blast_io = IO::String->new($blast_results);

  while (my $line = <$blast_io>) {
    chomp $line;
    my ($query, $subject, $pc_id, $align_length, $mismatches,
        $gap_openings, $q_start, $q_end, $s_start, $s_end,
        $e_val, $score) = split /\t/, $line;

    if (!defined $q_start) {
      die "$line";
    }

    my $q_length = ($q_end - $q_start) + 1;
    my $s_length = ($s_end - $s_start) + 1;

    if ($q_length > 100 && $score > 100 && $pc_id > 50) {
      $proc->(query => $query, subject => $subject);
    }
  }

}

my %res = ();

my %forward_matches = ();

for my $file (@files) {
  next if $file eq $base_file;
  my $matches_file = "$file.forward_matches";
  my $match_output = Bio::SeqIO->new(-file => ">$matches_file", -format => 'Fasta');

  warn "processing: $file\n";

  my %seen_subjects = ();

  my $forward_filter_proc = sub {
    my %args = @_;
    my $subject = $args{subject};
    if (!$seen_subjects{$subject}) {
      my $subject_seq = $seqs{$file}->{$subject};
      $match_output->write_seq($subject_seq);
      $seen_subjects{$subject} = 1;
    }
    $forward_matches{$args{query}} = $args{subject};
  };

  blast_filter $forward_filter_proc, $base_file, $file;

  my $rev_filter_proc = sub {
    my %args = @_;
    my $subject = $args{subject};
    my $query = $args{query};

    if ($forward_matches{$subject} eq $query) {
      if (exists $res{$subject}->{$file}) {
        if ($res{$subject}->{$file}->id() eq $query) {
          # good!
        } else {
          warn "replacing hit from $query to ", $res{$subject}->{$file},
            "with $query\n";
        }
      } else {
        $res{$subject}->{$file} = $seqs{$file}->{$query};
      }
    }
  };

  blast_filter $rev_filter_proc, $matches_file, $base_file;
}

my $group_count = 0;

for my $base_id (keys %res) {
  my %this_gene_map = %{$res{$base_id}};
  if (keys %this_gene_map < @files - 1) {
    # not enough orthologs
    next;
  }

  $group_count++;
  my $file_name = "$base_id.group";
  $file_name =~ s:/:_:g;
  $file_name = "groups/$file_name";
  my $seqout = Bio::SeqIO->new(-file => ">$file_name", '-format' => 'Fasta');
  my $base_seq = $seqs{$base_file}->{$base_id};
  $base_seq->desc($base_file);
  if (!defined $base_seq) {
    die "no sequence for $base_id\n";
  }
  $seqout->write_seq($base_seq);

  for my $file_name (sort keys %this_gene_map) {
    my $seq = $this_gene_map{$file_name};
    $seq->desc($file_name);
    my $new_id = $seq->id() . "_$file_name";
    $new_id =~ s/\.fas(ta)?//;
    $seq->id($new_id);
    $seqout->write_seq($seq);
  }
}

warn "Found $group_count groups\n";
