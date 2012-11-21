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

use Clone qw(clone);

with 'TuataraProc::Role::Process';

method output_files($out_dir)
{
  my $cloned_files = clone $self->in_dir_metadata()->{files};

  my ($all_files, $paired_files) =
    $self->all_files_map($cloned_files,
                         undef,
                         sub {
                           my $file_name = shift;
                           my $file_config = shift;

                           return $file_config->{type} eq 'paired_end';
                         });

  my @file_names =
    map {
      my $unpaired_file_name = "unpaired.$_";
      my $full_path = "$out_dir/$unpaired_file_name";
      if (-z $full_path) {
        unlink $full_path;
        ();
      } else {
        $unpaired_file_name;
      }
    } map { @$_ } @$paired_files;

  $cloned_files->{trimmomatic_se} =
    {
      type => 'single_end',
      paths => \@file_names,
    };

  return $cloned_files;
}

method make_args_from_pair($in_dir, $out_dir, $pair)
{
  return (join " ", map { "$in_dir/$_" } @$pair) . " " .
   (join " ", map { "$out_dir/$_ $out_dir/unpaired.$_" } @$pair);
}
