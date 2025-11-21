package LUCCDC::Jiujitsu::Commands::firewall;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;

sub run{
	print "Hello World!";

	my $testvar = 'ls';
	print $testvar, "\n";
	my @rules = `iptables -L`;

	my @IPtablesRules= ();
	my @NFtablesRules=();

	@IPtablesRules = `iptables -L`;
	@NFtablesRules = `nft list ruleset`;

	if (@IPtablesRules){
		print "@IPtablesRules,\n";
	}
	else{
		print "NFtables not in use.\n";
	} 

	if (@NFtablesRules){
		print "@NFtablesRules,\n";
	}
	else{ 
		print "NFtables not in use.\n";
	} 







	if ( grep { /22/ } @rules ) {
		print "SSH rules!\n";
	}

	exit;

}
1;
