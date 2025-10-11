package LUCCDC::jiujitsu;
use LUCCDC::jiujitsu::Util::Arguments qw(&parser);
use LUCCDC::jiujitsu::Commands::ssh;
use LUCCDC::jiujitsu::Commands::backup;

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

    #    'ssh'       => \&LUCCDC::jiujitsu::Commands::ssh::run,
    #    'backup'    => \&LUCCDC::jiujitsu::Commands::backup::run,
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
}

sub help {
    print "Jiu-Jitsu: Grapple your Linux systems.\n\n";

    print "[Commands]\n";
    print "\t", join( "\n\t", sort grep( !/^-/, keys %subcommands ) ), "\n";

    print "[Other]\n";
    print "\t", join( "\n\t", sort grep( /^-/, keys %subcommands ) ), "\n";

    exit;
}

1;
__END__

=head1 DESCRIPTION
 This command-line interface helps the Liberty CCDC Team to troubleshoot Linux systems.

=head1 USAGE


=head1 AUTHOR
 Judah Sotomayor
