package LUCCDC::Jiujitsu::Commands::stat;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser);
use LUCCDC::Jiujitsu::Util::Linux::Files qw(fgrep fgrep_flat);
my @options = ();

my %subcommands = ( "cpu" => \&cpu );

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {

    my ($cmdline) = @_;

    my %arg = $toplevel_parser->($cmdline);

    exit;
}

sub cpu {

    #    '/cpu /{usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}' /proc/stat
    # cpu  2022733 17813 1221519 60654770 26848 39 51488 0 0 0
    my @matches = fgrep_flat {
/cpu \s+ ([0-9]+) \s+ [0-9]+ \s+ ([0-9]+) \s+ ([0-9]+) \s+ ([0-9]+) .* /xms
    }
    "/proc/stat";

    my ( $user, $system, $idle ) = @matches;

    my $usage = ( $user + $system ) * 100 / ( $user + $system + $idle );

    printf( "%.5f%%\n", $usage );
    return $usage;
}

1;
