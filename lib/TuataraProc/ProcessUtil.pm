package TuataraProc::ProcessUtil;

=head1 NAME

TuataraProc::ProcessUtil - Utilities for process handling

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::ProcessUtil

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use perl5i::2;
use Moose;

use YAML qw(DumpFile LoadFile);
use String::CamelCase qw(decamelize);
use Module::Find;

func metadata_filename($dir)
{
  return "$dir/metadata.yaml";
}

func dir_metadata($dir)
{
  return LoadFile(metadata_filename($dir));
}

func write_dir_metadata($dir, $data)
{
  my $metadata_filename = metadata_filename($dir);
  if (-e $metadata_filename) {
    die "$metadata_filename already exists";
  }
  DumpFile($metadata_filename, $data);
}

func dir_creator($in_dir)
{
  my $in_dir_metadata = dir_metadata($in_dir);

  return $in_dir_metadata->{creator};
}

our $parent_package = "TuataraProc::Process";

func process_name($proc_mod_name)
{
  $proc_mod_name =~ s/^${parent_package}:://;
  return decamelize($proc_mod_name);
}

func next_out_dir($in_dir, $proc_name)
{
  if ($in_dir =~ /^([\d]+)-(.+)/) {
    my $next_dir_num = $1;
    $next_dir_num++;  # magical increment
    return "$next_dir_num-$proc_name";
  } else {
    die "$in_dir doesn't start with a number, eg. 12-proc_name\n";
  }
}

func available_processes()
{
  my @proc_mods = useall $parent_package;

  return map {
    my $mod_name = $_;
    my $proc_name = process_name($mod_name);
    ($proc_name, { package_name =>$_ });
  } @proc_mods;
}

# find the input directory when the user hasn't supplied one
func find_in_dirs()
{
  opendir my $dh, "." or die "can't open current directory: $!\n";

  my %ents = ();

  while (defined (my $ent = readdir $dh)) {
    next if grep { $_ eq $ent } qw(. ..);

    if ($ent =~ /^(\d\d)-(.*)/) {
      my $index = $1;
      my $name = $2;

      push @{$ents{$index}}, {
        index => $index,
        name => $name,
        file_name => $ent,
      };
    }
  }

  my @ent_indexes = sort keys %ents;

  my $last_index = $ent_indexes[-1];

  closedir $dh;

  return map { $_->{file_name}; } @{$ents{$last_index}};
}

func _fastq_from_metadata($metadata)
{
  my $files = $metadata->{files};

  my @fastq = map {
    map {
      if (ref $_) {
        @$_;
      } else {
        $_;
      }
    } @{$files->{$_}->{paths}};
  } keys %$files;

  return map { $_ => 1; } @fastq;
}

func _check_metadata_files($in_dir)
{
  my $metadata = dir_metadata($in_dir);

  my %fastq_from_metadata = _fastq_from_metadata($metadata);

  opendir my $dh, $in_dir || die "Can't open directory $in_dir: $!\n";

  my %fastq_in_dir = ();

  while (defined (my $ent = readdir $dh)) {
    if ($ent =~ /(\.fq|\.fastq)$/) {
      if (!exists $fastq_from_metadata{$ent}) {
        die "$ent isn't mentioned in the metadata in $in_dir";
      }

      $fastq_in_dir{$ent} = 1;
    }
  }

  map {
    if (!$fastq_in_dir{$_}) {
      die "$_ is mentioned in the metadata, bit isn't in $in_dir";
    }
  } keys %fastq_from_metadata;

  closedir($dh);
}

func run_process($config, $config_name, $in_dir)
{
  if (!defined $in_dir) {
    my @in_dirs = find_in_dirs();
    warn "no input directory given, using @in_dirs\n";

    map { run_process($config, $config_name, $_); } @in_dirs;

    return;
  }

  my $new_metadata = dir_metadata($in_dir);

  my $proc_config = $config->{processes}->{$config_name};

  if (!defined $proc_config) {
    croak "no configuration for: $config_name";
  }

  my $proc_type = $proc_config->{process_type};
  my %available_processes = available_processes();
  my $proc_details = $available_processes{$proc_type};

  if (!defined $proc_details) {
    croak "no process of type: $proc_type - exiting\n";
  }

  my $out_dir = next_out_dir($in_dir, $config_name);

  if (-e $out_dir) {
    croak "$out_dir already exists - exiting\n";
  } else {
    mkdir $out_dir || die "couldn't create $out_dir: $!\n";
  }

  my $in_dir_creator = dir_creator($in_dir);

  my $process = $proc_details->{package_name}->new(process_name => $config_name,
                                                   config => $config,
                                                   in_dir_metadata => $new_metadata);
  $process->pre_process($in_dir, $out_dir);
  try {
    $process->process($in_dir, $out_dir);
  } catch {
    warn "process() died: $_\n";
  };
  $process->post_process($in_dir, $out_dir);
}
