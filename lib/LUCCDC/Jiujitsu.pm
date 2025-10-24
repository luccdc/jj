package LUCCDC::Jiujitsu;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);

use LUCCDC::Jiujitsu::Commands::SSH;
use LUCCDC::Jiujitsu::Commands::backup;
use LUCCDC::Jiujitsu::Commands::useradd;
use LUCCDC::Jiujitsu::Commands::enum;
use LUCCDC::Jiujitsu::Commands::ports;
use LUCCDC::Jiujitsu::Commands::stat;
use LUCCDC::Jiujitsu::Commands::file;

# ABSTRACT: CLI to manage Linux
# VERSION

my @options = (
    {
        name => 'verbose',
        flag => '--verbose',
        val  => 0,
        pat  => flag_pat
    },
);

my %subcommands = (

    'file'      => \&LUCCDC::Jiujitsu::Commands::file::run,
    'ssh'       => \&LUCCDC::Jiujitsu::Commands::SSH::run,
    'enum'      => \&LUCCDC::Jiujitsu::Commands::enum::run,
    'ports'     => \&LUCCDC::Jiujitsu::Commands::ports::run,
    'backup'    => \&LUCCDC::Jiujitsu::Commands::backup::run,
    'useradd'   => \&LUCCDC::Jiujitsu::Commands::useradd::run,
    'stat'      => \&LUCCDC::Jiujitsu::Commands::stat::run,
    'help'      => \&help,
    '--version' => sub { print "version"; exit; },
    '--usage'   => sub { print "usage";   exit; },
    '--help'    => \&help,

);

my $core = parser( \@options, \%subcommands );

sub run {
    $core->(@ARGV);

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
