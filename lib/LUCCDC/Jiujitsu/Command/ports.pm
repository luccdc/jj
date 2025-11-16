package LUCCDC::Jiujitsu::Command::ports;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Linux::Proc qw(net_tcp);
use Carp;

sub abstract { "View open ports" }

sub execute {
    my ($self) = @_;

    map { format_tcp_line( @{$_} ) } net_tcp();

    exit;
}

sub format_tcp_line {
    my (
        $head,     $loc_addr, $loc_port, $rem_addr, $rem_port,
        $tcpstate, $inode,    $pid,      $cmdline
    ) = @_;

    $pid     ||= "?";
    $cmdline ||= "?";

    if ( $tcpstate eq "TCP_LISTEN" ) {
        format PORT =
 @>>>>>>>>>>>>>>>>:@<<<<<<@<<<<<<<<<<^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
 $loc_addr, $loc_port,$pid,    $cmdline
.

        local $~ = qw( PORT );
        write;
    }
    return;
}

1;
