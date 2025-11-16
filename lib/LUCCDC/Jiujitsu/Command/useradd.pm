package LUCCDC::Jiujitsu::Command::useradd;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(rhel_or_debian_return);
use Carp;

sub abstract   { "Create users" }
sub usage_desc { "$0 useradd <users>" }

my @DEFAULT_USERS = ( 'redboi', 'blueguy' );

sub description {
    chomp( my $s = <<"EODESC");
    Create <users> and add them to the sudoer group.

    By default, creates:
        @{[ join("\n\t",@DEFAULT_USERS) ]}
EODESC

    return $s;
}

sub execute {
    my ( $self, $opt, $users ) = @_;

    croak "Must be root" if $<;

    my $SUDO_GROUP = rhel_or_debian_return( "wheel", "sudo" );

    for my $user ( @{$users} ) {
        print "Adding user $user\n";
        `useradd -r -s /usr/bin/bash -G $SUDO_GROUP $user`;
        if ( $? == 0 ) {
            `passwd $user`;
        }
    }
    exit;
}

1;
