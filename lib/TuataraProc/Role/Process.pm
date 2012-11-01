package TuataraProc::Role::Process;

=head1 NAME

TuataraProc::Role::Process - Code with Process objects

=head1 SYNOPSIS

=head1 AUTHOR

Kim Rutherford C<< <kmr44@cam.ac.uk> >>

=head1 BUGS

Please report any bugs or feature requests to C<kmr44@cam.ac.uk>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc TuataraProc::Role::Process

=over 4

=back

=head1 COPYRIGHT & LICENSE

Copyright 2012 Kim Rutherford, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 FUNCTIONS

=cut

use perl5i::2;
use Moose::Role;

use Template::Tiny;

has proc_config => (
  is => 'ro',
  required => 1,
);

func _paired_files($in_dir)
{
  opendir(D, $in_dir) || die "Can't open directory $in_dir: $!\n";

  my %collector = ();

  while (defined (my $ent = readdir(D))) {
    next if grep { $_ eq $ent } qw(. .. metadata.yaml);
    if ($ent =~ /(.*_R)[12](_.*)/) {
      push @{$collector{"$1x$2"}}, $ent;
    } else {
      croak "unpaired file: $ent";
    }
  }

  closedir(D);

  return map { [ sort @{$collector{$_}} ] } sort keys %collector;

}

method make_files_arg_from_pair($in_dir, $out_dir, $pair)
{
  # default
  return join " ", @$pair;
}

method run_command_line($in_dir, $out_dir)
{
  my $template = Template::Tiny->new(
    TRIM => 1,
  );

  my $proc_config = $self->proc_config();

  my $command_line_template = $proc_config->{command_line_template};

  my @paired_files = _paired_files($in_dir);

  my %vars = (
    in_dir => $in_dir,
    out_dir => $out_dir,
  );

  my $command_line = '';

  if ($proc_config->{exec_type} eq 'paired') {
    for my $pair (@paired_files) {
      $vars{files} = $self->make_files_arg_from_pair($in_dir, $out_dir, $pair);

      $template->process(\$command_line_template, \%vars, \$command_line);

  warn "running: $command_line\n";
#  system $command_line;

    }
  }

}


method process($in_dir, $out_dir)
{
  $self->run_command_line($in_dir, $out_dir);
}
