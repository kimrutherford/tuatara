#!/usr/bin/env perl

use perl5i::2;
use Moose;

use File::Basename;
use Getopt::Long;
use Module::Find;

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

my $in_dir = shift;
my $proc_name = shift;

my @proc_mods = useall TuataraProc::Process;;

my %proc_mods = map {
  my $mod_name = $_;
  my $proc_name = TuataraProc::ProcessUtil::process_name($mod_name);
  ($proc_name, { package_name =>$_ });
} @proc_mods;

my $proc_details = $proc_mods{$proc_name};

if (!defined $proc_details) {
  die "no process for: $proc_name - exiting\n";
}

use Data::Dumper;
$Data::Dumper::Maxdepth = 5;
warn Dumper([\%proc_mods]), "\n";

my $out_dir = TuataraProc::ProcessUtil::next_out_dir($in_dir, $proc_name);

if (-e $out_dir) {
  die "$out_dir already exists - exiting\n";
} else {
  mkdir $out_dir || die "couldn't create $out_dir: $!\n";
}

my $in_dir_creator = TuataraProc::ProcessUtil::dir_creator($in_dir);


$proc_details->{package_name}->new()->process($in_dir, $out_dir);
