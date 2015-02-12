#!/usr/bin/env perl

use warnings;
use strict;

use Bio::DB::Taxonomy;
use Bio::Tree::Tree;

use LWP::Simple;

use GDBM_File;

my $db = Bio::DB::Taxonomy->new(-source => 'entrez');

tie my %uniprot_id_taxon, 'GDBM_File', '.uniprot_taxon_id_cache', &GDBM_WRCREAT, 0640;
tie my %taxon_name_cache, 'GDBM_File', '.taxon_cache', &GDBM_WRCREAT, 0640;

my $debug = 0;

sub get_lineage
{
  my $arg = shift;

  my $SEPARATOR = '<:=:>';

  if (exists $taxon_name_cache{$arg}) {
    warn "from lineage cache: $arg -> $taxon_name_cache{$arg}\n" if $debug;
    return split /$SEPARATOR/, $taxon_name_cache{$arg};
  }

  my $taxon;

  if ($arg =~ /^\d+/) {
    warn "get_taxon(-taxonid => $arg)\n" if $debug;
    $taxon = $db->get_taxon(-taxonid => $arg);
  } else {
    # for examples like: Epinephelus coioides (Orange-spotted grouper)
    # just get the first bit
    if ($arg =~ /([^\(+]+?)\s+\(/) {
      warn "get_taxon(-name => $1)\n" if $debug;
      $taxon = $db->get_taxon(-name => $1);
      warn "  returned: $taxon\n" if $taxon && $debug;
    }

    if (!$taxon) {
      # try with the full text
      warn "get_taxon(-name => $arg)\n" if $debug;
      $taxon = $db->get_taxon(-name => $arg);
    }
  }

  if (!defined $taxon) {
    warn "can't find lineage for $arg\n";
    return "UNKNOWN";
  }

  my $tree = Bio::Tree::Tree->new(-node => $taxon);
  my @taxa = $tree->get_nodes;

  my @res = map {
    my $t = $_;

    $db->get_taxon(-taxonid => $t->id())->scientific_name();
  } @taxa;

  warn "adding to lineage cache: $arg -> @res\n" if $debug;
  $taxon_name_cache{$arg} = join $SEPARATOR, @res;
  return @res;
}

my $uniprot_api_url = 'http://www.uniprot.org/uniprot/?format=tab&columns=id,taxon&query=id:';

sub get_org_name_for_id
{
  my $id = shift;

  if (exists $uniprot_id_taxon{$id}) {
    warn "from cache: $id -> $uniprot_id_taxon{$id}\n" if $debug;
    return $uniprot_id_taxon{$id};
  }

  my $content = get($uniprot_api_url . $id);

  if (!$content) {
    warn "can't find taxon for: $id\n";
    return undef;
  }

  my @bits = split /\n/, $content;

  if ($bits[0] =~ /Entry\s+taxon/) {
    my ($ret_id, $taxon) = split /\t/, $bits[1];

    if ($ret_id ne $id) {
      die "server returned a different ID than we requested: $ret_id <> $id\n";
    } else {
      warn "adding to cache: $id -> $taxon\n" if $debug;
      $uniprot_id_taxon{$id} = $taxon;
      return $taxon;
    }
  } else {
    die qq(header from UniProt should be "Entry taxon", not "$bits[0]"\n);
  }
}

while (defined (my $line = <>)) {
  chomp $line;
  my ($query, $subject, $pc_id, $align_length, $mismatches,
      $gap_openings, $q_start, $q_end, $s_start, $s_end,
      $e_val, $score) = split /\t/, $line;

  (my $id = $subject) =~ s/(sp|tr)\|([\d\w]+)\|([\d\w]+)/$2/;

  my $org_name = get_org_name_for_id($id);

  if (defined $org_name) {
    my @lineage = get_lineage($org_name);

    print "$line\t", join ("\t", @lineage), "\n";
  }
}

