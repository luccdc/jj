package LUCCDC::Jiujitsu::Command::stat;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Linux::Files qw(fgrep fgrep_flat);

sub abstract { "Tools for system status" }

sub execute {
    my ($self) = @_;
    cpu();
    exit;
}

sub cpu {
    my @matches = fgrep_flat {
/cpu \s+ ([0-9]+) \s+ [0-9]+ \s+ ([0-9]+) \s+ ([0-9]+) \s+ ([0-9]+) .* /xms
    }
    "/proc/stat";

    my ( $user, $system, $idle ) = @matches;

    my $usage = ( $user + $system ) * 100 / ( $user + $system + $idle );

    printf( "%.5f%%\n", $usage );
    exit;
}

1;
