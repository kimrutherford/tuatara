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
use File::Copy;

use Template::Tiny;

has process_name => (
  is => 'ro',
  required => 1,
);

has config => (
  is => 'ro',
  required => 1,
);

has in_dir_metadata => (
  is => 'ro',
  required => 1,
);

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

method all_files_map($files, $proc, $paired_filter_proc)
{
  my @paired_files = ();
  my @ignored_paired_files = ();

  my @all_files =
    map {
      my $library_name = $_;
      my $file_config = $files->{$library_name};
      map {
        my $files_ref = $_;
        if (ref $files_ref) {
          my @mapped_files = map {
            if (defined $proc) {
              $proc->($_);
            } else {
              $_;
            }
          } @$files_ref;
          if (!defined $paired_filter_proc || $paired_filter_proc->($_, $file_config)) {
            push @paired_files, [@mapped_files];
          } else {
            push @ignored_paired_files, [@mapped_files];
          }
          @mapped_files;
        } else {
          if (defined $proc) {
            $_ = $proc->($_);
          }
          $_;
        }
      } @{$file_config->{paths}};
    } keys %$files;

  return (\@all_files, \@paired_files, \@ignored_paired_files);
}

# return the hash of files that were created by the process
method output_files($out_dir)
{
  return $self->in_dir_metadata()->{files};
}

method process($in_dir, $out_dir)
{
  my $template = Template::Tiny->new(
    TRIM => 1,
  );

  my $process_name = $self->process_name();

  my $proc_config = $self->config()->{processes}->{$process_name};

  my %new_metadata = (
    creator => $process_name,
    source => $in_dir,
    config => $self->config(),
  );

  my $command_line_template = $proc_config->{command_line_template};

  my ($all_files, $keep_paired_files, $ignored_paired_files) =
    $self->all_files_map($self->in_dir_metadata->{files},
                         undef,
                         sub {
                           my $val = shift;
                           my $file_config = shift;

                           if ($file_config->{type} eq 'paired_end') {
                             # keep;
                             1;
                           } else {
                             0;
                           }
                         });

  my %vars = (
    in_dir => $in_dir,
    out_dir => $out_dir,
    config => $self->config(),
    new_metadata => \%new_metadata,
  );

  my $command_line = '';

  my $proc = sub {
    $template->process(\$command_line_template, \%vars, \$command_line);
    system $command_line;
  };

  given ($proc_config->{exec_type}) {
    when ('all_pairs') {
      $vars{args} = $self->make_args_from_pairs($in_dir, $out_dir, $keep_paired_files);
      $proc->();
    }
    when ('paired') {
      for my $pair (@$keep_paired_files) {
        $vars{args} = $self->make_args_from_pair($in_dir, $out_dir, $pair);
        $proc->();
      }
    }
    when ('all_files') {
      $vars{args} = $self->make_args($in_dir, $out_dir, $all_files);
      $proc->();
    }
    default {
      die "unknown exec_type: ", $proc_config->{exec_type};
    }
  }

  my $new_files = $self->output_files($out_dir);

  $new_metadata{files} = $new_files;

  for my $pair (@$ignored_paired_files) {
    for my $pair_file (@$pair) {
      copy("$in_dir/$pair_file", "$out_dir/$pair_file")
        or die "can't copy $pair_file: $!";
    }
  }

  # write metadata only once the process succeeds
  TuataraProc::ProcessUtil::write_dir_metadata($out_dir, \%new_metadata);
}
