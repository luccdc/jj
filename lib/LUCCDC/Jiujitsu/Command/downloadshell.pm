package LUCCDC::Jiujitsu::Command::downloadshell;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::DownloadContainer
  qw(&create_container &run_command &destroy_container);

sub abstract {
"Creates a shell that has access to the internet, even when the host firewall blocks outbound traffic";
}

sub description {
    my ($self) = @_;
    chomp( my $s = <<"EODESC");
${\(abstract())}

Options:
EODESC
    return $s;
}

sub opt_spec {
    return (
        [
            'sneaky-ip|i=s',
            'The IP address to give the container on the network',
            { required => 1 }
        ],
        [
            'name|n=s',
            'The name to give the container. Must be unique!',
            { required => 1 }
        ],
    );
}

sub execute {
    my ( $self, $opt, $args ) = @_;

    my $sneaky_ip = $opt->{sneaky_ip};
    my $namespace = $opt->{name};

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

1;
