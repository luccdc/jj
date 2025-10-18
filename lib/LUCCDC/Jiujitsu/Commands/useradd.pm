package LUCCDC::Jiujitsu::Commands::useradd;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser :patterns);
use LUCCDC::Jiujitsu::Util::Linux::Files qw(fgrep);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro
  qw(rhel_or_debian_do rhel_or_debian_return platform);

my @paths_to_save = (
    '/etc',             '/var/lib', '/var/www', '/lib/systemd',
    '/usr/lib/systemd', '/opt'
);

my @options = (
    {
        name => 'users',
        flag => '--users|-u',
        val  => "",
        pat  => string_pat,
    },

);

my %subcommands = ( '--help' => \&help );

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {
    my ($cmdline) = @_;
    my %arg = $toplevel_parser->($cmdline);

    my $SUDO_GROUP = rhel_or_debian_return( "wheel", "sudo" );

    for my $user ( split( /,/, $arg{"users"} ) ) {
        print "Adding user $user\n";
        `useradd -r -s /usr/bin/bash -G $SUDO_GROUP $user`;
        `passwd $user`;
    }
    exit;
}

sub help {
    print "Create backup users.\n";
    print "\t--users (-u): Comma separated list of users to create.\n";
    exit;
}

1;
