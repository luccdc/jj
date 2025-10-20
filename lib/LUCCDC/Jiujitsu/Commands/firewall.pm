package LUCCDC::Jiujitsu::Commands::firewall;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;

sub run{
	print "Hello World!";

	my $testvar = 'ls';
	print $testvar, "\n";
	my @rules = `iptables -L`;
	if ( grep { /22/ } @rules ) {
		print "SSH rules!\n";
	}

	exit;

}

1;
