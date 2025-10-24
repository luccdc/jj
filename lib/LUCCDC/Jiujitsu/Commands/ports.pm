package LUCCDC::Jiujitsu::Commands::ports;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments   qw(&parser);
use LUCCDC::Jiujitsu::Util::Linux::Proc qw(net_tcp);
my @options = ();

my %subcommands = ();

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {
    my @cmdline = @_;

    my %arg = $toplevel_parser->(@cmdline);

    map { format_tcp_line( @{$_} ) } net_tcp();

    exit;
}

sub format_tcp_line {
    my (
        $head,     $loc_addr, $loc_port, $rem_addr, $rem_port,
        $tcpstate, $inode,    $pid,      $cmdline
    ) = @_;

    if ( $tcpstate eq "TCP_LISTEN" ) {
        format PORT =
 @<<<@>>>>>>>>>>>>>>>>:@<<<<<<<<<<<<<<<<<@<<<<<<<<<<@<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 "tcp",               $loc_addr, $loc_port,    $pid, $cmdline
.

        local $~ = qw( PORT );
        write;
    }
    return;
}

1;
