package LUCCDC::jiujitsu::Commands::stat;
use strictures 2;
use LUCCDC::jiujitsu::Util::Arguments    qw(&parser);
use LUCCDC::jiujitsu::Util::Linux::Files qw(fgrep);
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
    my ( undef, $user, $nice, $system, $idle, $iowait, $irq, $softirq ) =
      split( /\s+/, fgrep( "/proc/stat", /cpu (.*)/ ) );

    my $usage = ( $user + $system ) * 100 / ( $user + $system + $idle );
    printf( "%.5f%\n", $usage );
}
