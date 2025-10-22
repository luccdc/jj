package LUCCDC::Jiujitsu::Util::DownloadContainer;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION = 1.00;
@EXPORT_OK =
  qw(create_container run_command destroy_container run_command_once);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT_OK, );

# This module provides the ability to create containers that can execute commands
#   and access the internet, even when the host system will typically block such
#   access with the outbound firewall
#
# The crux of this function exists in three functions:
# - create_container: Given an IP address and a namespace name (both optional),
#     creates a new container that will send outbound traffic as that IP address
#     on the default interface of the host system
# - run_command: Given a command and a container name (container name optional),
#     runs the given command in the network namespace of the container
# - destroy_container: Given the namespace name, performs cleanup and deletes the
#     namespace. This is important to run, as resources exist outside of the process
#     and persist when jiujitsu is done executing
#
# There is a convenience function, run_command_once, that will create a container,
#   run a command inside it, and then perform cleanup
#
# The default container name is "downloadshell". Each container must have a unique
#   name, or it create_container will die

my $pat_octet = qr/[0-9]{1,2}|[1-2][0-9]{2}/xms;
my $firewall  = `which nft 2>/dev/null` ? "nft" : "iptables";

sub create_container {
    my $sneaky_ip = shift;
    my $namespace = ( shift // "downloadshell" ) || "downloadshell";

    my $tunnel_net = find_tunnel_ip();

    die "You must be root to run this shell" unless $> == 0;
    die "There is already a download shell in use with that name"
      if `ip netns` =~ qr/$namespace/xms;

    `ip link add $namespace.0 type veth peer name $namespace.1`;
    `ip netns add $namespace`;
    `ip link set $namespace.0 up`;
    `ip link set $namespace.1 netns $namespace`;

    my $wan_ip = format_ip($tunnel_net);
    `ip addr add $wan_ip/30 dev $namespace.0`;

    `ip -n $namespace link set lo up`;
    `ip -n $namespace link set $namespace.1 up`;
    my $lan_ip = format_ip( $tunnel_net + 1 );
    `ip -n $namespace addr add $lan_ip/30 dev $namespace.1`;
    `ip -n $namespace route add default via $wan_ip`;

    my $public_if = ( `ip route` =~ m/default[^\n]*dev\s+([^\s]+)/xms )[0];

    toggle_on_setting("/proc/sys/net/ipv4/ip_forward");

    if ( $firewall eq "nft" ) {
        `nft delete table inet $namespace 2>/dev/null`;
        `nft add table inet $namespace`;
`nft 'add chain inet $namespace postrouting { type nat hook postrouting priority srcnat; policy accept; }'`;
    }

    if ( $sneaky_ip eq '' ) {
        if ( $firewall eq "nft" ) {
`nft 'add rule inet $namespace postrouting oifname "$public_if" masquerade'`;
        }
        else {
`iptables -t nat -A POSTROUTING -o "$public_if" -j MASQUERADE -m comment --comment $namespace`;
        }
    }
    else {
        if ( $firewall eq "nft" ) {
`nft 'add rule inet $namespace postrouting ip saddr $lan_ip snat to $sneaky_ip'`;
        }
        else {
`iptables -t nat -A POSTROUTING -s $lan_ip -j SNAT --to-source $sneaky_ip -m comment --comment $namespace`;
        }

        toggle_on_setting("/proc/sys/net/ipv4/conf/all/proxy_arp");
        toggle_on_setting("/proc/sys/net/ipv4/conf/$public_if/proxy_arp");
        `ip route add $sneaky_ip/32 dev lo 2>/dev/null`;
    }

    return $namespace;
}

sub run_command {
    my $cmd = shift;
    my $ns  = ( shift // "downloadshell" ) || "downloadshell";

    system("ip netns exec $ns $cmd");

    return;
}

sub destroy_container {
    my $ns = ( shift // "downloadshell" ) || "downloadshell";

    `ip netns delete $ns`;

    if ( $firewall eq "nft" ) {
        `nft delete table inet $ns`;
    }
    else {
        my $rule_id =
          ( `iptables --line-numbers -vn -t nat -L POSTROUTING` =~
              m/([0-9]+)[^\n]*$ns/xms )[0];
        `iptables -t nat -D POSTROUTING $rule_id`;
    }

    return;
}

sub run_command_once {
    my $cmd       = shift;
    my $sneaky_ip = shift;
    my $namespace = shift;

    my $ns = create_container( $sneaky_ip, $namespace );
    run_command( $cmd, $ns );
    destroy_container($ns);

    return;
}

sub toggle_on_setting {
    my $setting = shift;
    open( my $proc_setting, '>', $setting )
      or die "Could not open proc setting: $setting";
    print $proc_setting "1";
    close($proc_setting) or print "Could not close setting: $setting";
    return;
}

sub parse_subnet {
    my ( $a, $b, $c, $d, $sn ) = shift =~ m{
        ($pat_octet)\.($pat_octet)\.($pat_octet)\.($pat_octet)/([0-9]+)
    }xms;

    return [
        ( $a << 24 ) | ( $b << 16 ) | ( $c << 8 ) | ( $d + 0 ),
        ( 0xFFFFFFFF >> ( 32 - $sn ) ) << ( 32 - $sn )
    ];
}

sub get_subnets {
    my @current_subnets = `ip addr` =~ m{
        inet\s+
        ($pat_octet\.$pat_octet\.$pat_octet\.$pat_octet/[0-9]+)
    }xmsg;

    return map { parse_subnet($_) } @current_subnets;
}

sub ip_in_subnet {
    my ( $mask, $subnet, $ip ) = @_;

    return ( $subnet & $mask ) == ( $ip & $mask );
}

sub find_tunnel_ip {

    my $start_ip = 0xAC1FFFFD + 4;
    my @subnets  = get_subnets();

  OUTER:
    while (1) {
        $start_ip = $start_ip - 4;
        foreach (@subnets) {
            next OUTER if ip_in_subnet( @{$_}[1], @{$_}[0], $start_ip );
        }

        if ( !ip_in_subnet( 0xFFF00000, 0xAC100000, $start_ip ) ) {
            die "IP address exhaustion when trying to find an IP address!";
        }

        return $start_ip;
    }
    return;
}

sub format_ip {
    my $ip = shift;
    return sprintf "%d.%d.%d.%d", ( $ip >> 24 ) & 0xFF, ( $ip >> 16 ) & 0xFF,
      ( $ip >> 8 ) & 0xFF, $ip & 0xFF;
}

1;
