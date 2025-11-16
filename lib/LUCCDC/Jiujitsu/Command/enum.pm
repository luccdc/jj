package LUCCDC::Jiujitsu::Command::enum;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Command::ports;
sub abstract { "Enumerate the system" }

sub description {
    return "Provide a system enumeration useful for detecting basic problems.";
}

sub execute {
    my ($self) = @_;

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
    LUCCDC::Jiujitsu::Command::ports::execute();
    exit;
}

1;
