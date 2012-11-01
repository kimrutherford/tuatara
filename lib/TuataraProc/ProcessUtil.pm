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

func dir_metadata($dir)
{
  return LoadFile "$dir/metadata.yaml";
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
