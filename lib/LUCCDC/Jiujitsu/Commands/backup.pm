package LUCCDC::Jiujitsu::Commands::backup;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments        qw(&parser :patterns);
use LUCCDC::Jiujitsu::Util::Linux::Files     qw(fgrep);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(&rhel_or_debian_do &platform);

my @paths_to_save = (
    '/etc',             '/var/lib', '/var/www', '/lib/systemd',
    '/usr/lib/systemd', '/opt'
);

my @options = (
    {
        name => 'tarballs',
        flag => '--tarballs|-t',
        val  => ['/var/games/.luanti.tgz'],
        type => 'list',
    },
    {
        name => 'paths',
        flag => '--paths|-p',
        val  => [],
        type => 'list',
    }
);

my %subcommands = ( '--help' => \&help );

my $toplevel_parser = parser( \@options, \%subcommands );

my $DEFAULT_PATHS = '/etc /var/lib /var/www /lib/systemd /usr/lib/systemd /opt';

sub run {
    my @cmdline = @_;
    my %arg     = $toplevel_parser->(@cmdline);

    my $paths_strings = join( ' ', @{ $arg{'paths'} } );
    my $status        = `tar -czpf /tmp/i.tgz $DEFAULT_PATHS $paths_strings`;

    for my $tarball ( @{ $arg{'tarballs'} } ) {
        `cp /tmp/i.tgz $tarball`;
    }
    exit;
}

sub help {
    print "Backup files into a tarball.\n";
    print "Takes two flags:\n";
    print "\t--tarball: Comma separated list of tarballs to create.\n";
    print
      "\t--paths: Comma separated list of paths to add to the default paths.\n";
    print "\nBy default, backs up:\n$DEFAULT_PATHS\n";
    exit;
}

1;
