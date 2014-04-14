use Module::Build;

my $build = Module::Build->new(
    module_name => 'Net::Hlld',
    dist_abstract => 'hlld client in pure Perl',
    dist_author => 'Fabrice Gabolde <fgabolde@weborama.com>',
    dist_version_from => 'lib/Net/Hlld.pm',
    license => 'gpl',
    configure_requires => {
        'Module::Build' => '0.36_14',
    },
    test_requires => {
        'File::Temp' => 0,
        'Scalar::Util' => 0,
        'Test::Deep' => 0,
        'Test::Exception' => 0,
        'Test::More' => 0,
    },
    requires => {
        'perl' => '5.10.0',
        'autodie' => 0,
        'Carp' => 0,
        'constant' => 0,
        'Digest::SHA' => 0,
        'IO::Socket::INET' => 0,
        'Moo' => 0,
        'strict' => 0,
        'Throwable::Error' => 0,
        'utf8' => 0,
        'warnings' => 0,
    },
    add_to_cleanup => [ 'Net-Hlld-*' ],
    meta_merge => {
        resources => {
            repository => 'https://github.com/Weborama/Net-Hlld.git',
            bugtracker => 'https://github.com/Weborama/Net-Hlld/issues',
        },
    },);

$build->create_build_script;
