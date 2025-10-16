package LUCCDC::jiujitsu;
use strictures 2;
use LUCCDC::jiujitsu::Util::Arguments qw(&parser);

use LUCCDC::jiujitsu::Commands::SSH;
use LUCCDC::jiujitsu::Commands::backup;
use LUCCDC::jiujitsu::Commands::useradd;
use LUCCDC::jiujitsu::Commands::ports;
use LUCCDC::jiujitsu::Commands::stat;

# ABSTRACT: CLI to manage Linux
# VERSION

my @options = (
    {
        name => 'verbose',
        flag => '--verbose',
        val  => 0,
        pat  => qr/                  /xms
    },
);

my %subcommands = (

    'ssh'       => \&LUCCDC::jiujitsu::Commands::SSH::run,
    'ports'     => \&LUCCDC::jiujitsu::Commands::ports::run,
    'backup'    => \&LUCCDC::jiujitsu::Commands::backup::run,
    'useradd'   => \&LUCCDC::jiujitsu::Commands::useradd::run,
    'stat'      => \&LUCCDC::jiujitsu::Commands::stat::run,
    'help'      => \&help,
    '--version' => sub { print "version"; exit; },
    '--usage'   => sub { print "usage";   exit; },
    '--help'    => \&help,

);

my $core = parser( \@options, \%subcommands );

sub run {
    my $cmdline = join " ", @ARGV;
    $core->($cmdline);

    help();
    exit;
}

sub help {
    print "Jiu-Jitsu: Grapple your Linux systems.\n\n";

    print "[Commands]\n";
    print "\t", join( "\n\t", sort grep( { !/^-/ } keys %subcommands ) ), "\n";

    print "[Other]\n";
    print "\t", join( "\n\t", sort grep( { /^-/ } keys %subcommands ) ), "\n";

    exit;
}

1;
