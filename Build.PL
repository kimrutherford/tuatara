use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'TuataraProc',
    license             => 'perl',
    dist_author         => q{Kim Rutherford <kmr44@cam.ac.uk>},
    dist_version_from   => 'lib/TuataraProc.pm',
    requires            => {
      perl                    => '5.12.0',
      'perl5i::2'             => 0,
      'Moose'                 => 0,
      'YAML'                  => 0,
      'YAML::Any'             => 0,
      'File::Basename'        => 0,
      'Getopt::Long'          => 0,
      'Module::Find'          => 0,
      'String::CamelCase'     => 0,
    },
    build_requires => {
        'Test::More' => 0,
    },
    add_to_cleanup      => [ 'TuataraProc-*' ],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
