package TuataraProc::Process::Trimmomatic;

=head1 NAME

TuataraProc::Process::Trimmomatic - Trim using Trimmomatic

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::Process::Trimmomatic

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

method make_files_arg_from_pair($in_dir, $out_dir, $pair)
{
  return (join " ", map { "$in_dir/$_" } @$pair) . " " .
   (join " ", map { "$out_dir/$_ $out_dir/unpaired.$_" } @$pair);
}
