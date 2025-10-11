package LUCCDC::jiujitsu::Commands::ports;
use LUCCDC::jiujitsu::Util::Arguments qw(&parser);
my @options = ();

my %subcommands = ();

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {

    my $cmdline = join " ", @_;

    my %arg = $toplevel_parser->($cmdline);

    print $arg{'port'};

    for my $line ( grep( /LISTEN/, `ss -peanuts` ) ) {
        my ( $netid, $state, $recvq, $sendq, $local, $peer, $process ) =
          split( /\s+/, $line );
        print join( "\t", ( $netid, $local, $process ) ), "\n";
    }

    # Do something
    exit;
}
