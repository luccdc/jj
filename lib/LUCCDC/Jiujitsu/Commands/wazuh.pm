package LUCCDC::Jiujitsu::Commands::wazuh;
use strictures 2;

use Carp;
use Cwd            qw(abs_path);
use File::Basename qw(dirname);
use File::Path     qw(make_path);
use IPC::Open2;
use POSIX ":sys_wait_h";

use LUCCDC::Jiujitsu::Util::Logging          qw(message error warning header);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(platform);
use LUCCDC::Jiujitsu::Util::Arguments        qw(&parser);
use LUCCDC::Jiujitsu::Util::DownloadContainer
  qw(&create_container &run_closure &destroy_container);

my $wazuh_password = "";

sub get_wazuh_password {
    if ( $wazuh_password eq "" ) {
        print "Enter password for the admin user: ";
        $wazuh_password = <STDIN>;
        chomp $wazuh_password;
        print "\n";
    }
    return $wazuh_password;
}

my @options = (
    {
        name => 'wazuh_version',
        flag => '--wver|-V',
        val  => '4.14',
        type => 'string'
    },
    {
        name => 'sneaky_ip',
        flag => '--sneaky-ip|-I',
        val  => '',
        type => 'string'
    }
);

my %subcommands = (
    '--help'  => \&help,
    '-h'      => \&help,
    'install' => \&install
);

my $parser = parser( \@options, \%subcommands );

sub run {
    my @cmdline = @_;

    die "You must be root to install Wazuh" unless $> == 0;
    die "A hostname must be set!"
      if `hostnamectl` =~ qr/Static\+hostname:\s+\(unset\)/xms;

    $parser->(@cmdline);

    exit;
}

sub help {
    my ($progname) = $0 =~ m{(^\/]+)$}xms;

    print <<"END_HELP";
Installs and configures Wazuh using the download shell

The Wazuh install process is incompatible with ELK

Subcommand options:
    -V, --wver=VERSION         The version of Wazuh to install
    -I, --sneaky-ip            The IP address to use when downloading packages, defaults to the default external IP

Configuration notes:
    The following ports need to be available:
    - 443/tcp: Management for Wazuh
    - 1514/tcp: Wazuh agent port
    - 1515/tcp: Wazuh agent port

END_HELP

    return;
}

sub install {
    my (%args) = @_;

    `mkdir /tmp/wazuh`;
    chdir("/tmp/wazuh");

    my $vers = $args{"wazuh_version"};
    download_installer($vers);

    my $ns = create_container( $args{"sneaky_ip"} );
    run_closure(
        sub {
            if ( platform() eq "debian" ) {
                `./wazuh-install.sh -dw deb -da x86_64`;
            }
            elsif ( platform() eq "rhel" ) {
                `./wazuh-install.sh -dw rpm -da x86_64`;
            }
            `curl -o config.yml https://packages.wazuh.com/$vers/config.yml`;
        },
        $ns
    );
    destroy_container($ns);

    exit;
}

sub download_installer {
    my ($vers) = @_;

    if (`which curl 2>/dev/null`) {
`curl -o wazuh-install.sh https://packages.wazuh.com/$vers/wazuh-install.sh`;
        `chmod 744 wazuh-install.sh`;
        return;
    }
    elsif (`which wget 2>/dev/null`) {
`wget -O wazuh-install.sh https://packages.wazuh.com/$vers/wazuh-install.sh`;
        `chmod 744 wazuh-install.sh`;
        return;
    }

    die("!!! Could not find program to download files with");
}

1;
