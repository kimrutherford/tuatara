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

method all_files_map($files, $proc, $split_proc)
{
  my @paired_files = ();
  my @ignored_paired_files = ();

  my @split_results = ();

  my @all_files =
    map {
      my $library_name = $_;
      my $file_config = $files->{$library_name};
      map {
        my $files_ref = $_;
        my @res = ();
        if (ref $files_ref) {
          map {
            if (defined $proc) {
              $proc->($_);
            }
            push @res, $_;
          } @$files_ref;
        } else {
          if (defined $proc) {
            $_ = $proc->($_);
          }
          push @res, $_;
        }

        if (defined $split_proc) {
          my @bits = $split_proc->($_, $file_config);
          for (my $i = 0; $i < @bits; $i++) {
            if (defined $bits[$i]) {
              push @{$split_results[$i]}, $bits[$i];
            }
          }
        }

        @res;
      } @{$file_config->{paths}};
    } keys %$files;

  return (\@all_files, @split_results);
}

# return the hash of files that were created by the process
method output_files($out_dir)
{
  return $self->in_dir_metadata()->{files};
}

method pre_process($in_dir, $out_dir)
{
  # default - do nothing
}

method post_process($in_dir, $out_dir)
{
  # default - do nothing
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

  my ($all_files, $paired_end_files, $single_end_files, $mate_pair_files) =
    $self->all_files_map($self->in_dir_metadata()->{files},
                         undef,
                         sub {
                           my $val = shift;
                           my $file_config = shift;

                           given ($file_config->{type}) {
                             when ('paired_end') {
                               return ($val, undef, undef);
                             }
                             when ('single_end') {
                               return (undef, $val, undef);
                             }
                             when ('mate_pair') {
                               return (undef, undef, $val);
                             }
                             default {
                               die "unknown type: ", $file_config->{type}, "\n";
                             }
                           }
                         });

  my %vars = (
    in_dir => $in_dir,
    out_dir => $out_dir,
    config => $self->config(),
    in_dir_metadata => $self->in_dir_metadata(),
    new_metadata => \%new_metadata,
  );

  my $command_line = '';

  my $proc = sub {
    $template->process(\$command_line_template, \%vars, \$command_line);
    system $command_line;
  };

  given ($proc_config->{exec_type}) {
    when ('all_pairs') {
      $vars{args} = $self->make_args_from_pairs($in_dir, $out_dir, $paired_end_files, $single_end_files, $mate_pair_files);
      $proc->();
    }
    when ('paired_end') {
      for my $pair (@$paired_end_files) {
        $vars{args} = $self->make_args_from_pair($in_dir, $out_dir, $pair);
        $proc->();
      }
    }
    when ('mate_pair') {
      for my $pair (@$paired_end_files) {
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

  for my $file_name (@$all_files) {
    my $dest_file = "$out_dir/$file_name";
    if (!-f $dest_file) {
      copy("$in_dir/$file_name", $dest_file)
        or die "can't copy $file_name: $!";
    }
  }

  # write metadata only once the process succeeds
  TuataraProc::ProcessUtil::write_dir_metadata($out_dir, \%new_metadata);
}
