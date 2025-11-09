package LUCCDC::Jiujitsu::Commands::SSH;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;

use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);

use LUCCDC::Jiujitsu::Util::Service qw(&check_service);

use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(platform);

sub local_ip {
    return "127.0.0.1";
}
my $ssh_service_name = do {
	if (platform() eq 'debian') {
		'ssh';
	}
	else {
		'sshd';
	}
};

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
    '--help' => \&help,
    'help'   => \&help
);
my %empty = ();

my $toplevel_parser = parser( \@options, \%subcommands );
my $subcmd_parser   = parser( \@options, \%empty );

sub run {
    my @cmdline = @_;
    
    my %arg = $toplevel_parser->(@cmdline);
    help();
    exit;
}

sub help {
    print "Usage: jj ssh <subcommand> [options]\n\n";
    print "[Commands]\n";
    print "\t", join( "\n\t", sort grep( { !/^-/ } keys %subcommands ) ), "\n";
    exit;
}

sub check {
    my ($cmdline) = @_;

    $subcmd_parser->($cmdline);
    service_check();
    exit;
}

sub service_check {

    if ( check_service($ssh_service_name) ) {
        print "SSH is running";
    }
    else {
        print "SSH is not running";
    }
    
    print "\n";
    return;
}

sub check_bind {
    print "SSH is listening on:\n";
    for my $line ( grep { /LISTEN.*ssh/ } `ss -peanuts` ) {
        my @elems = split( /\s+/, $line );
        print $elems[4], "\n";
    }
    print "\n";
    exit;
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
    exit;
}

sub check_login {
    my ($cmdline) = @_;

    my %subcommands = ();
    my %arg         = parser( \@options, \%subcommands )->($cmdline);
    `ssh $arg{'user'}" . "@" . "$arg{'host'}`;
    exit;
}

# sub check_service_running {
#     my $self = shift;
#     print "It runs!";
#     print "parameter: " $self->some_parameter;
# }

1;
