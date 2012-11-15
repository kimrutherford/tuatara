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

has process_name => (
  is => 'ro',
  required => 1,
);

has proc_config => (
  is => 'ro',
  required => 1,
);

func _paired_files($in_dir)
{
  opendir(D, $in_dir) || die "Can't open directory $in_dir: $!\n";

  my %collector = ();

  while (defined (my $ent = readdir(D))) {
    next if grep { $_ eq $ent } qw(. ..);
    next if $ent =~ /metadata.yaml/;
    next if $ent =~ /^unpaired\./;  # from Trimmomatic
    if ($ent =~ /(.*_R)[12](_.*)/) {
      push @{$collector{"$1x$2"}}, $ent;
    } else {
    }
  }

  closedir(D);

  return map { [ sort @{$collector{$_}} ] } sort keys %collector;

}

func _add_in_dir($in_dir, $files)
{
  return map { "$in_dir/$_" } @$files;
}

method make_args_from_pair($in_dir, $out_dir, $pair)
{
  # default
  return join " ", _add_in_dir($in_dir, $pair);
}

method make_args($in_dir, $out_dir, $file_arg)
{
  my @file_args = ();
  if (ref $file_arg) {
    @file_args = @$file_arg;
  } else {
    push @file_args, $file_arg;
  }

  return join " ", _add_in_dir($in_dir, \@file_args);
}

method post_process($in_dir, $out_dir)
{
  # default - no nothing
}

method run_command_line($in_dir, $out_dir)
{
  my $template = Template::Tiny->new(
    TRIM => 1,
  );

  my $proc_config = $self->proc_config();

  my %new_metadata = (
    creator => $self->process_name(),
    source => $in_dir,
    config => $proc_config,
  );

  TuataraProc::ProcessUtil::write_dir_metadata($out_dir, \%new_metadata);

  my $command_line_template = $proc_config->{command_line_template};

  my @paired_files = _paired_files($in_dir);
  my @all_files = map { @$_ } @paired_files;

  my %vars = (
    in_dir => $in_dir,
    out_dir => $out_dir,
  );

  my $command_line = '';

  my $proc = sub {
    $template->process(\$command_line_template, \%vars, \$command_line);
    system $command_line;
  };

  given ($proc_config->{exec_type}) {
    when ('all_pairs') {
      $vars{args} = $self->make_args_from_pairs($in_dir, $out_dir, [@paired_files]);
      $proc->();
    }
    when ('paired') {
      for my $pair (@paired_files) {
        $vars{args} = $self->make_args_from_pair($in_dir, $out_dir, $pair);
        $proc->();
      }
    }
    when ('all_files') {
      $vars{args} = $self->make_args($in_dir, $out_dir, [@all_files]);
      $proc->();
    }
    default {
      die "unknown exec_type: ", $proc_config->{exec_type};
    }
  }
}


method process($in_dir, $out_dir)
{
  $self->run_command_line($in_dir, $out_dir);
}
