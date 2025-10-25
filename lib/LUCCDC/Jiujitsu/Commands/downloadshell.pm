package LUCCDC::Jiujitsu::Commands::downloadshell;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::DownloadContainer
  qw(&create_container &run_command &destroy_container);
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);

my @options = (
    {
        name => 'sneaky_ip',
        flag => '--sneaky-ip|-i',
        val  => '',
        pat  => string_pat,
    },
    {
        name => 'name',
        flag => '--name|-n',
        val  => '',
        pat  => string_pat
    },

);

my %subcommands = (
    '--help' => \&help,
    '-h'     => \&help,
    'help'   => \&help,
);

sub run {
    my %arg = parser( \@options, \%subcommands )->(@_);

    my $sneaky_ip = $arg{"sneaky_ip"};
    my $namespace = $arg{"name"};

    my $ns = create_container( $sneaky_ip, $namespace );

    my $ps1_command =
"bash --login -i -c 'export PS1=\"\\033[0;32m($ns)\\033[0m \$PS1\"; exec bash --login -i'";

    my $SUDO_UID = $ENV{"SUDO_UID"};

    if ( defined $SUDO_UID ) {
        my $name = `id -un $SUDO_UID`;
        chomp $name;
        run_command( "sudo -u $name $ps1_command", $ns );
    }
    else {
        run_command( $ps1_command, $ns );
    }

    destroy_container($ns);

    exit;
}

sub help {
    print <<"END_HELP";
Creates a shell that has access to the internet, even when the host firewall blocks outbound traffic

Options:
	-i, --sneaky-ip=IP    The IP address to give the container on the network
	-n, --name=NAME       The name to give the container. Must be unique!
	-h, --help            Print this help message

END_HELP
    exit;
}

1;
