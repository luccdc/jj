package LUCCDC::Jiujitsu::Command::ssh;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::systemd qw(&check_service);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro
  qw(rhel_or_debian_do rhel_or_debian_return platform);

sub local_ip {
    return "127.0.0.1";
}
my $ssh_service_name = rhel_or_debian_return( "sshd", "ssh" );

sub opt_spec {
    return (
        [
            'port|p=i' => 'Port to connect to',
            { default => 22 }
        ],
        [
            'host|H=s' => 'Host to connect to',
            { default => => local_ip() }
        ],
        [
            'user|u=s' => 'User to log in as',
            { default => "root" }
        ]
    );
}

my %subcommands = (
    'check' => \&check,
    'net'   => \&check_bind,
    'fw'    => \&check_fw,
    'login' => \&check_login,
);
my %empty = ();

sub execute {
    service_check();

    exit;
}

sub check {
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
    my ( $opt, $arg ) = @_;

    `ssh $opt->{'user'}" . "@" . "$opt->{'host'}`;
    return;
}

# sub check_service_running {
#     my $self = shift;
#     print "It runs!";
#     print "parameter: " $self->some_parameter;
# }

1;
