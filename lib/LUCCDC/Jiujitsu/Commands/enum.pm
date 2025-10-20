package LUCCDC::Jiujitsu::Commands::enum;
use strictures 2;
use LUCCDC::Jiujitsu::Commands::ports;

use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);

my @options = ();

my %subcommands = ( '--help' => \&help );

my $toplevel_parser = parser( \@options, \%subcommands );

sub run {
    my ($cmdline) = @_;
    my %arg = $toplevel_parser->($cmdline);

    print "\n==== CPU INFO\n";
    print grep { /Core|Thread/ } `lscpu`, "\n";
    print "\n==== MEMORY/STORAGE INFO\n";
    print `free -h`, "\n";
    print `df -h`,   "\n";
    print "\n==== IP INFO\n";
    print `ip -V`,       "\n";
    print `iptables -V`, "\n";
    print `nft -V`,      "\n";
    print `uname -a`,    "\n";

    print "\n==== PORTS INFO\n";
    LUCCDC::Jiujitsu::Commands::ports::run("");
    exit;
}

sub help {
    my () = @_;

    print "Enumerate the system.\n";
    return;
}

1;
