package LUCCDC::Jiujitsu::Util::Linux::Proc;
use Carp;
use strictures 2;
use parent                               qw(Exporter);
use Symbol                               qw( gensym );
use LUCCDC::Jiujitsu::Util::Linux::Files qw(slurp_to_array);
use LUCCDC::Jiujitsu::Util::Regex        qw(%RX);
use File::Basename;
use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(net_tcp map_sockets_to_processes);
%EXPORT_TAGS = (
    DEFAULT => \@EXPORT_OK,

    #patterns => [qw(number_pat string_pat)]
);

my @tcpstates = qw(
  DUMMY
  TCP_ESTABLISHED
  TCP_SYN_SENT
  TCP_SYN_RECV
  TCP_FIN_WAIT1
  TCP_FIN_WAIT2
  TCP_TIME_WAIT
  TCP_CLOSE
  TCP_CLOSE_WAIT
  TCP_LAST_ACK
  TCP_LISTEN
  TCP_CLOSING
  TCP_NEW_SYN_RECV
  TCP_MAX_STATES
);

sub ip_from_hex {
    my ($hexip) = @_;
    my @octets = map { hex } ( $hexip =~ m/../xmsg );
    return join q{.}, reverse(@octets);

}

sub net_tcp {

    my %map_sockets_to_processes = map_sockets_to_processes();

    my @connection_lines = slurp_to_array('/proc/net/tcp');
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
            print {*STDERR} $line, "\n";
            print {*STDERR} "hex($stat) is 0\n";
        }
        my $pid = $map_sockets_to_processes{$inode};
        push @output,
          (
            [
                $head,          ip_from_hex($loc_addr),
                hex($loc_port), ip_from_hex($rem_addr),
                hex($rem_port), $tcpstates[ hex($stat) ],
                $inode,         $pid,
                extract_cmdline($pid),
            ]
          );
    }

    return @output;
}

# TODO Rename to something that is meaningful?
sub map_sockets_to_processes {
    return map { filter_sockets($_) } glob('/proc/[0-9]*/fd/*');
}

sub filter_sockets {
    my ($filename) = @_;
    if ( defined( readlink($filename) )
        && ( readlink($filename) =~ m/^socket:\[([0-9]+)\]/xms ) )
    {
        my $inode = $1;
        my $pid   = basename( dirname( dirname($filename) ) );
        return ( $inode => $pid );
    }
    return ();
}

sub extract_cmdline {
    my ($pid) = @_;
    return if !defined($pid);

    open my $file, '<', "/proc/$pid/cmdline"
      or return 'no cmdline';

    my $cmdline = <$file>;

    close $file or croak "Failed to close '$file'";

    $cmdline =~ s/\0/ /xmsg;
    return $cmdline;
}
1;
