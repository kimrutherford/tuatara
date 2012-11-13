use strict;
use warnings;
use Test::More tests => 4;
use Test::File;

BEGIN {
  use Cwd;
  push @INC, getcwd() . '/lib';
}

use YAML qw(DumpFile LoadFile);
use File::Temp qw/ tempdir /;
use File::Copy qw(copy);

use TuataraProc::ProcessUtil;

my $config = LoadFile 'config.yaml';

my $temp_dir = tempdir();
my $temp_raw_fastq_dir = "$temp_dir/00-raw-fastq";
mkdir $temp_raw_fastq_dir;

my $raw_fastq_dir = 't/data/raw-fastq/';

{
  opendir my $dh, $raw_fastq_dir or die "can't open $raw_fastq_dir: $!\n";

  while (defined (my $ent = readdir $dh)) {
    next if grep { $_ eq $ent } qw(. ..);

    copy "$raw_fastq_dir/$ent", $temp_raw_fastq_dir or die "$!";
  }

  closedir $dh;
}

my $old_dir = getcwd();

chdir $temp_dir;

TuataraProc::ProcessUtil::run_process($config, 'trimmomatic_low_qual_window');

file_exists_ok('01-trimmomatic_low_qual_window');
file_exists_ok('01-trimmomatic_low_qual_window/BDOVECACXX_NZGL00054_TUATARA_NoIndex_L008_R2_001.fastq');

TuataraProc::ProcessUtil::run_process($config, 'fastqc');

file_exists_ok('02-fastqc');
file_exists_ok('02-fastqc/BDOVECACXX_NZGL00054_TUATARA_NoIndex_L008_R2_001_fastqc/fastqc_report.html');

