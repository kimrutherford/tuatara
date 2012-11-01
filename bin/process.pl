#!/usr/bin/env perl

use perl5i::2;
use Moose;

use File::Basename;
use Getopt::Long;
use YAML qw(DumpFile LoadFile);

BEGIN {
  (my $base_dir = $0) =~ s|(.*)/bin/.*|$1|;
  unshift @INC, "$base_dir/lib";
}

use TuataraProc::ProcessUtil;

my $dry_run = 0;
my $do_help = 0;

if (@ARGV < 2) {
  usage();
}

my $result = GetOptions ("dry-run|T" => \$dry_run,
                         "help|h" => \$do_help);

sub usage
{
  my $message = shift;

  if (defined $message) {
    $message .= "\n";
  } else {
    $message = '';
  }

  die qq|${message}usage:
|;
}

if (!$result || $do_help) {
  usage();
}

my $config_file = shift;
my $config = LoadFile $config_file;
my $in_dir = shift;
my $config_name = shift;

TuataraProc::ProcessUtil::run_process($config, $in_dir, $config_name);

