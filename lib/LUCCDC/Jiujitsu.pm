package LUCCDC::Jiujitsu;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser);

use LUCCDC::Jiujitsu::Commands::SSH;
use LUCCDC::Jiujitsu::Commands::backup;
use LUCCDC::Jiujitsu::Commands::useradd;
use LUCCDC::Jiujitsu::Commands::ports;
use LUCCDC::Jiujitsu::Commands::stat;
use LUCCDC::Jiujitsu::Commands::daemon;

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

    'ssh'       => \&LUCCDC::Jiujitsu::Commands::SSH::run,
    'ports'     => \&LUCCDC::Jiujitsu::Commands::ports::run,
    'backup'    => \&LUCCDC::Jiujitsu::Commands::backup::run,
    'useradd'   => \&LUCCDC::Jiujitsu::Commands::useradd::run,
    'stat'      => \&LUCCDC::Jiujitsu::Commands::stat::run,
    'procwatch' => \&LUCCDC::Jiujitsu::Commands::daemon::procwatch,
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
