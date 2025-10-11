package LUCCDC::jiujitsu::Commands::ssh;
use LUCCDC::jiujitsu::Util::Logging;

use LUCCDC::jiujitsu::Util::Arguments qw(&parser :patterns);
use LUCCDC::jiujitsu::Util::systemd   qw(&check_service);
use LUCCDC::jiujitsu::Util::Linux::PerDistro
  qw(rhel_or_debian_do rhel_or_debian_return platform);

#use Linux::Systemd::Daemon;

# Default method, called by the containing app when the subcommand is used.

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

    my $cmdline = join " ", @_;

    my %arg = $toplevel_parser->($cmdline);

    print $arg{'port'};

    # Do something
    exit;
}

sub check {
    my $cmdline = join " ", @_;
    $subcmd_parser->($cmdline);
    service_check();
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
    for my $line ( grep( /LISTEN.*ssh/, `ss -peanuts` ) ) {
        my @elems = split( /\s+/, $line );
        print $elems[4], "\n";
    }
    print "\n";
    return;
}

sub check_fw {

    sub _check_fw_rhel {
        print error("NOT IMPLEMENTED on RHEL\n");
    }

    sub _check_fw_debian {
        print error("NOT IMPLEMENTED on Debian\n");

    }

    # Check the firewall
    rhel_or_debian_do( \&_check_fw_rhel, \&_check_fw_debian );
}

sub check_login {
    my $cmdline       = join " ", @_;
    my @check_options = (
        {
            name => 'user',
            flag => '--user|-u',
            val  => "root",
            pat  => string_pat,
        }
    );

    my %subcommands = ();
    my %arg         = parser( \@options, \%subcommands )->($cmdline);
    print "ssh $arg{'user'}" . "@" . "$arg{'host'}";
    return;
}

# sub check_service_running {
#     my $self = shift;
#     print "It runs!";
#     print "parameter: " $self->some_parameter;
# }

1;
