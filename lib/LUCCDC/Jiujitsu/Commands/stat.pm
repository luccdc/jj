package LUCCDC::Jiujitsu::Commands::stat;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser);
use LUCCDC::Jiujitsu::Util::Linux::Files qw(fgrep fgrep_flat);
my @options = ();

my %subcommands = (
    "cpu"    => \&cpu,
    "help"   => \&help,
    "--help" => \&help,
    "-h"     => \&help,
);

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {

    my @cmdline = @_;

    my %arg = $toplevel_parser->(@cmdline);

    help();
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
    exit;
}

sub help {
    print <<'END_HELP';
Tools for system status

Usage:
	jj stat <subcommand> <options>

Subcommands:
	cpu:  Print current CPU Usage
	help: Print this help message

END_HELP
    exit;
}

1;
