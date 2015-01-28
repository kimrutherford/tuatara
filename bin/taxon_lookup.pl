#!/usr/bin/env perl

use warnings;
use strict;

use Bio::DB::Taxonomy;
use Bio::Tree::Tree;

use GDBM_File;

my @taxonids = @ARGV;
my @lineages = ();

my $db = Bio::DB::Taxonomy->new(-source => 'entrez');

tie my %taxon_name_cache, 'GDBM_File', '.taxon_cache', &GDBM_WRCREAT, 0640;
my $taxon_id_to_name = ();

sub get_lineage
{
  my $arg = shift;

  my $SEPARATOR = '<:=:>';

  if (exists $taxon_name_cache{$arg}) {
    return split /$SEPARATOR/, $taxon_name_cache{$arg};
  }

  my $taxon;

  if ($arg =~ /^\d+/) {
    $taxon = $db->get_taxon(-taxonid => $arg);
  } else {
    $taxon = $db->get_taxon(-name => $arg);
  }
  my $tree = Bio::Tree::Tree->new(-node => $taxon);
  my @taxa = $tree->get_nodes;

  my @res = map {
    my $t = $_;

    $db->get_taxon(-taxonid => $t->id())->scientific_name();
  } @taxa;

  $taxon_name_cache{$arg} = join $SEPARATOR, @res;

  return @res;
}

for my $arg (@ARGV) {
  my @lineage = get_lineage($arg);

  print ((join "\t", @lineage), "\n");
}
