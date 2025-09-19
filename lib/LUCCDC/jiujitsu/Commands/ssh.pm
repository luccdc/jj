package LUCCDC::jiujitsu::Commands::ssh;
use Linux::Systemd::Daemon;

#use LUCCDC::jiujitsu::Commands::ssh::test;

# Default method, called by the containing app when the subcommand is used.
sub run {

    # my ($self) = @_;
    # my $command = $self->{'command'};

    # print "$command\n";

    # # You can even call sub-commands from here.
    # my $subcmd = LUCCDC::jiujitsu::Commands::ssh::test->dofoo();
    # $subcmd->run;
    my ( $a, $test ) = @_;
    print "Hello world!!" . $a;

    # Do something
}

sub check_service {
    print 'Working';
    return;
}

sub check_network {
    print "Checking network!";
    return;
}

sub check_login {
    return;
}

# sub check_service_running {
#     my $self = shift;
#     print "It runs!";
#     print "parameter: " $self->some_parameter;
# }

1;
