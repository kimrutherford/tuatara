package TuataraProc::Process::Abyss;

=head1 NAME

TuataraProc::Process::Abyss - Run the ABySS assembler

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::Process::Abyss

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

with 'TuataraProc::Role::Process';

use File::Copy;

has files_before_process => (is => 'rw', init_arg => undef);

method pre_process($in_dir, $out_dir)
{
  # collect file name from the current directory and then after
  # running abyss copy any new files to out_dir
  opendir my $d, "." or die "can't open '.': $!";

  my @existing = readdir $d;
  $self->files_before_process(\@existing);

  closedir $d;
}

method post_process($in_dir, $out_dir)
{
  my @existing = @{$self->files_before_process()};
  my %existing = map { $_ => 1 } @existing;

  # copy any new files to out_dir
  opendir my $d, "." or die "can't open '.': $!";

  while (defined (my $ent = readdir $d)) {
    if (!$existing{$ent}) {
      move $ent, "$out_dir/$ent" or die "can't move $ent: $!";
    }
  }

  closedir $d;
}


method make_args_from_pairs($in_dir, $out_dir)
{
  my $in_dir_metadata = $self->in_dir_metadata();

  my %libs = ();
  my %mp = ();
  my @se = ();

  my $files_conf = $in_dir_metadata->{files};

  for my $library_name (keys %$files_conf) {
    my $library_conf = $files_conf->{$library_name};
    my @lanes = @{$library_conf->{paths}};

    for (my $i = 0; $i < @lanes; $i++) {
      my $lane = $lanes[$i];
      my $library_type = $library_conf->{type};
      given ($library_type) {
        when ('paired_end') {
          $libs{$library_name . "_$i"} = $lane;
        }
        when ('mate_pair') {
          $mp{$library_name . "_$i"} = $lane;
        }
        when ('single_end') {
          push @se, $lane;
        }
        default {
          die "unknown library type: $library_type\n";
        }
      }
    }
  }

  my $libs_string = 'lib="' . (join ' ', keys %libs) . '"';
  my $lib_file_names_string =
    join ' ', map {
      my $libs_key = $_;
      "$libs_key='" . (join " ", map { "$in_dir/$_" } @{$libs{$libs_key}}) . "'";
    } keys %libs;
  my $mp_string = 'mp="' . (join ' ', keys %mp) . '"';
  my $mp_file_names_string =
    join ' ', map {
      my $mp_key = $_;
      "$mp_key='" . (join " ", map { "$in_dir/$_" } @{$mp{$mp_key}}) . "'";
    } keys %mp;
  my $se_file_names_string =
    'se="' . (join " ", map { "$in_dir/$_" } @se) . '"';

  my $args = "$libs_string $lib_file_names_string $mp_string " .
    "$mp_file_names_string $se_file_names_string";

  return $args;
}

1;
