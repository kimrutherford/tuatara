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
my $in_dir = undef;

if (@ARGV < 2) {
  usage();
}

my $result = GetOptions ("input_directory|i=s" => \$in_dir,
                         "dry-run|T" => \$dry_run,
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
$0 [-i input_directory] <process_name> [<process_name> ...]
|;
}

if (!$result || $do_help) {
  usage();
}

my $config_file = shift;
my $config = LoadFile $config_file;

if (!@ARGV) {
  usage "no processes given";
}

for my $config_name (@ARGV) {
  TuataraProc::ProcessUtil::run_process($config, $config_name, $in_dir);

  # use the input directory for the first process only
  $in_dir = undef;
}

