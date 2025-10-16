package LUCCDC::jiujitsu::Commands::SSH;
use strictures 2;
use LUCCDC::jiujitsu::Util::Logging;

use LUCCDC::jiujitsu::Util::Arguments qw(&parser :patterns);

use LUCCDC::jiujitsu::Util::systemd qw(&check_service);

use LUCCDC::jiujitsu::Util::Linux::PerDistro
  qw(rhel_or_debian_do rhel_or_debian_return platform);

sub local_ip {
    return "127.0.0.1";
}
my $ssh_service_name = rhel_or_debian_return( "sshd", "ssh" );

my @options = (
    {
        name => 'port',
        flag => '--port|-p',
        val  => 22,
        pat  => number_pat,
    },
    {
        name => 'host',
        flag => '--host|-h',
        val  => local_ip(),
        pat  => string_pat,
    },
    {
        name => 'user',
        flag => '--user|-u',
        val  => "root",
        pat  => string_pat,
    }
);

my %subcommands = (
    'check'  => \&check,
    'net'    => \&check_bind,
    'fw'     => \&check_fw,
    'login'  => \&check_login,
    '--help' => sub { print "ssh help"; exit; }
);
my %empty = ();

my $toplevel_parser = parser( \@options, \%subcommands );
my $subcmd_parser   = parser( \@options, \%empty );

sub run {
    my ($cmdline) = @_;

    my %arg = $toplevel_parser->($cmdline);

    exit;
}

sub check {
    my ($cmdline) = @_;

    $subcmd_parser->($cmdline);
    service_check();
    return;
}

sub service_check {

    if ( check_service("ssh") ) {
        print "SSH is running";
    }
    else {
        print "SSH is not running";
    }

    return;
}

sub check_bind {
    print "SSH is listening on:\n";
    for my $line ( grep { /LISTEN.*ssh/ } `ss -peanuts` ) {
        my @elems = split( /\s+/, $line );
        print $elems[4], "\n";
    }
    print "\n";
    return;
}

sub check_fw {

    # my $rhel = sub {
    #     print error("NOT IMPLEMENTED on RHEL\n");
    #   }

    #   my $deb = sub {
    #     print error("NOT IMPLEMENTED on Debian\n");

    #   }

    # Check the firewall
    # rhel_or_debian_do( $rhel, $deb );
    return;
}

sub check_login {
    my ($cmdline) = @_;

    my %subcommands = ();
    my %arg         = parser( \@options, \%subcommands )->($cmdline);
    `ssh $arg{'user'}" . "@" . "$arg{'host'}`;
    return;
}

# sub check_service_running {
#     my $self = shift;
#     print "It runs!";
#     print "parameter: " $self->some_parameter;
# }

1;
