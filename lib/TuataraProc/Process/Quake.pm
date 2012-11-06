package TuataraProc::Process::Quake;

=head1 NAME

TuataraProc::Process::Quake - A process to run Quake

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::Process::Quake

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

use File::Temp qw/ tempfile /;

with 'TuataraProc::Role::Process';

has temp_filename => (is => 'rw', init_arg => undef);

method make_args_from_pairs($in_dir, $out_dir, $pairs)
{
  my ($temp_fh, $temp_filename) = tempfile();

  for my $pair (@$pairs) {
    print $temp_fh (join " ", map { "$in_dir/$_" } @$pair) . "\n";
  }

  $self->temp_filename($temp_filename);

  return "-f $temp_filename";
}

method post_process
{
  unlink $self->temp_filename();
}
