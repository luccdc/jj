package LUCCDC::Jiujitsu::Commands::downloadshell;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::Linux::Files qw(fgrep);
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser :patterns);

use Env qw($SUDO_UID);

my @options = (
    {
        name => 'sneaky_ip',
        flag => '--sneaky-ip|-i',
        val  => '',
        pat  => string_pat,
    }
);

my $firewall = `which nft 2>/dev/null` ? "nft" : "iptables";

sub toggle_on {
    my $setting = shift;
    open( my $proc_setting, '>', $setting )
      or die "Could not open proc setting: $setting";
    print $proc_setting "1";
    close($proc_setting) or print "Could not close setting: $setting";
    return;
}

sub run {
    my %arg = parser( \@options, {} )->(shift);

    my $sneaky_ip = $arg{"sneaky_ip"};
    if ( not $sneaky_ip ) {
        $sneaky_ip = ( `ip route` =~ m/default[^\n]*src\s+([0-9.]+)/xms )[0];
    }

    die "You must be root to run this shell" unless $> == 0;
    die "There is already a download shell in use"
      if `ip netns` =~ qr/downloader/xms;

    print "Spawning shell with IP ", $sneaky_ip, ", using ", $firewall, "...\n";

    `ip link add downloader.0 type veth peer name downloader.1`;
    `ip netns add downloader`;
    `ip link set downloader.0 up`;
    `ip link set downloader.1 netns downloader`;

    `ip addr add 172.31.254.253/30 dev downloader.0`;

    `ip -n downloader link set lo up`;
    `ip -n downloader link set downloader.1 up`;
    `ip -n downloader addr add 172.31.254.254/30 dev downloader.1`;
    `ip -n downloader route add default via 172.31.254.253`;

    my $public_if = ( `ip route` =~ m/default[^\n]*dev\s+([^\s]+)/xms )[0];

    toggle_on("/proc/sys/net/ipv4/ip_forward");

    if ( $firewall eq "nft" ) {
        `nft delete table inet downloadshell 2>/dev/null`;
        `nft add table inet downloadshell`;
`nft 'add chain inet downloadshell postrouting { type nat hook postrouting priority srcnat; policy accept; }'`;
    }

    if ( $arg{"sneaky_ip"} eq '' ) {
        if ( $firewall eq "nft" ) {
`nft 'add rule inet downloadshell postrouting oifname "$public_if" masquerade'`;
        }
        else {
            `iptables -t nat -A POSTROUTING -o "$public_if" -j MASQUERADE`;
        }
    }
    else {
        if ( $firewall eq "nft" ) {
`nft 'add rule inet downloadshell postrouting saddr 172.31.254.254 snat to $sneaky_ip'`;
        }
        else {
`iptables -t nat -A POSTROUTING -s 172.31.254.254 -j SNAT --to-source $sneaky_ip`;
        }

        toggle_on("/proc/sys/net/ipv4/conf/all/proxy_arp");
        toggle_on("/proc/sys/net/ipv4/conf/$public_if/proxy_arp");
        `ip route add $sneaky_ip/32 dev downloader.0`;
    }

    my $ps1_command =
"bash --login -i -c 'export PS1=\"\\033[0;32m(download-shell)\\033[0m \$PS1\"; exec bash --login -i'";

    if ( defined $SUDO_UID ) {
        my $name = `id -un $SUDO_UID`;
        chomp $name;
        system("ip netns exec downloader sudo -u $name $ps1_command");
    }
    else {
        system("ip netns exec downloader $ps1_command");
    }

    `ip netns delete downloader`;

    if ( $firewall eq "nft" ) {
        `nft delete table inet downloadshell`;
    }
    else {
        if ( $arg{"sneaky_ip"} eq '' ) {
            my $rule_id =
              ( `iptables --line-numbers -vn -t nat -L POSTROUTING` =~
                  m/([0-9]+[^\n]*MASQUERADE)/xms )[0];
            `iptables -t nat -D POSTROUTING $rule_id`;
        }
        else {
            my $rule_id =
              ( `iptables --line-numbers -vn -t nat -L POSTROUTING` =~
                  m/([0-9]+[^\n]*$sneaky_ip)/xms )[0];
            `iptables -t nat -D POSTROUTING $rule_id`;
        }
    }

    exit;
}
1;
