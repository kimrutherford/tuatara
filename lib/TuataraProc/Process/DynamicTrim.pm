package TuataraProc::Process::DynamicTrim;

=head1 NAME

TuataraProc::Process::DynamicTrim - Process using SolexaQA DynamicTrim

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::Process::DynamicTrim

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

method process($in_dir, $out_dir)
{
  system "cd $in_dir; for i in *; do head -100 \$i > ../$out_dir/\$i; done";

  return 1;
}
