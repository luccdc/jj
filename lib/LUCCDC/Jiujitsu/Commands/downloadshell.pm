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
    {
        name => 'help',
        flag => '--help|-h',
        val  => 0,
        pat  => qr/ /xms
    }
);

sub run {
    my %arg = parser( \@options, {} )->(shift);

    if ( $arg{"help"} ) {
        help();
    }

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
    print <<"END";
Creates a shell that has access to the internet, even when the host firewall blocks outbound traffic

Options:

    --sneaky-ip|-i: Specifies the IP address to give the container on the network
    --name|-n:      Specifies the name to give the container. Must be unique!
    --help|-h:      Prints this help message
END
    exit;
}

1;
