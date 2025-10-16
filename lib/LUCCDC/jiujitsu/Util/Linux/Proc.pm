package LUCCDC::jiujitsu::Util::Linux::Proc;
use strictures 2;
use parent                               qw(Exporter);
use Symbol                               qw( gensym );
use LUCCDC::jiujitsu::Util::Linux::Files qw(slurp_to_array);
use File::Basename;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(net_tcp map_sockets_to_processes);
%EXPORT_TAGS = (
    DEFAULT => \@EXPORT_OK,

    #patterns => [qw(number_pat string_pat)]
);

@tcpstates = (
    "DUMMY",
    "TCP_ESTABLISHED",     #1
    "TCP_SYN_SENT",        #2
    "TCP_SYN_RECV",        #3
    "TCP_FIN_WAIT1",       #4
    "TCP_FIN_WAIT2",       #5
    "TCP_TIME_WAIT",       #6
    "TCP_CLOSE",           #7
    "TCP_CLOSE_WAIT",      #8
    "TCP_LAST_ACK",        #9
    "TCP_LISTEN",          #10
    "TCP_CLOSING",         #11
    "TCP_NEW_SYN_RECV",    #12
    "TCP_MAX_STATES,"      #13
);

sub ip_from_hex {
    my ($hexip) = @_;
    my @octets = map( hex($_), ( $hexip =~ m/../g ) );
    return join( '.', reverse(@octets) );

}

sub net_tcp {

    my %map_sockets_to_processes = map_sockets_to_processes();

    my @connection_lines = slurp_to_array("/proc/net/tcp");
    shift @connection_lines;    # Skip header line.

    my @output = ();
    for my $line (@connection_lines) {

        my (
            $head,     $loc_addr, $loc_port, $rem_addr, $rem_port,
            $stat,     $tx_queue, $rx_queue, $tr,       $tmwhen,
            $retrnsmt, $uid,      $timeout,  $inode,    $tail
          )
          = $line =~ m{ ^\s*
                        ($RX{dec}): \s+
                        ($RX{hex8}):($RX{hex4}) \s+
                        ($RX{hex8}):($RX{hex4}) \s+
                        ($RX{hex2}) \s+
                        ($RX{hex8}):($RX{hex8}) \s+
                        ($RX{hex2}):($RX{hex8}) \s+
                        ($RX{hex8}) \s+
                        ($RX{dec}) \s+
                        ($RX{dec}) \s+
                        ($RX{dec}) (.*)
                }xms;

        if ( hex($stat) == 0 ) {
            print STDERR $line, "\n";
            print STDERR "hex($stat) is 0\n";
        }
        my $pid = $map_sockets_to_processes{$inode};
        push @output,
          (
            [
                $head,          ip_from_hex($loc_addr),
                hex($loc_port), ip_from_hex($rem_addr),
                hex($rem_port), $tcpstates[ hex($stat) ],
                $inode,         $pid,
                process_cmdline($pid),
            ]
          );
    }

    return @output;
}

# TODO Rename to something that is meaningful?
sub map_sockets_to_processes {
    return map( filter_sockets($_), </proc/[0-9]*/fd/*> );
}

sub process_cmdline {
    my ($pid) = @_;

    my $file = gensym();
    open $file, "<", "/proc/$pid/cmdline"
      or return "no cmdline";
    my $cmdline = <$file>;
    $cmdline =~ s/\0/ /g;
    return $cmdline;
}

sub filter_sockets {
    my ($filename) = @_;

    if ( readlink($filename) =~ /^socket:\[([0-9]+)\]/ ) {
        my $inode = $1;
        my $pid   = basename( dirname( dirname($filename) ) );
        return ( $inode => $pid );
    }
    return ();
}
