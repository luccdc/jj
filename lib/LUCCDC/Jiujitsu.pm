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
use LUCCDC::Jiujitsu::Commands::downloadshell;
use LUCCDC::Jiujitsu::Commands::elk;
use LUCCDC::Jiujitsu::Commands::check;

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

    'backup'        => \&LUCCDC::Jiujitsu::Commands::backup::run,
    'downloadshell' => \&LUCCDC::Jiujitsu::Commands::downloadshell::run,
    'enum'          => \&LUCCDC::Jiujitsu::Commands::enum::run,
    'file'          => \&LUCCDC::Jiujitsu::Commands::file::run,
    'help'          => \&help,
    'ports'         => \&LUCCDC::Jiujitsu::Commands::ports::run,
    'useradd'       => \&LUCCDC::Jiujitsu::Commands::useradd::run,
    'ssh'           => \&LUCCDC::Jiujitsu::Commands::SSH::run,
    'stat'          => \&LUCCDC::Jiujitsu::Commands::stat::run,
    'elk'           => \&LUCCDC::Jiujitsu::Commands::elk::run,
    'check'         => \&LUCCDC::Jiujitsu::Commands::check::run,
    '--version'     => sub { print "version"; exit; },
    '--usage'       => sub { print "usage";   exit; },
    '--help'        => \&help,

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
