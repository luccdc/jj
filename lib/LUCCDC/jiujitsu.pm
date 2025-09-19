package LUCCDC::jiujitsu;
use LUCCDC::jiujitsu::Util::Arguments;
use strictures;

# ABSTRACT: CLI to manage Linux
# VERSION

my @options = (
    { flag => '-in',       val => '-', pat => qr/ \s* =? \s* (\S*) /xms },
    { flag => '-out',      val => '-', pat => qr/ \s* =? \s* (\S*) /xms },
    { flag => '-len',      val => 24,  pat => qr/ \s* =? \s* (\d+) /xms },
    { flag => '--verbose', val => 0,   pat => qr/                  /xms },
);

my %subcommands = ( 'ssh' =>, \&LUCCDC::jiujitsu::Commands::ssh::run );

my %meta_options = (
    '--version' => sub { print "version"; exit; },
    '--usage'   => sub { print "usage";   exit; },
    '--help'    => sub { print "help";    exit; },
    '--man'     => sub { print "man";     exit; },
);

sub run {
    my $cmdline = join " ", @ARGV;
    my $core    = \&LUCCDC::jiujitsu::Util::Arguments::parser;
    $core->( \@options, \%subcommands, \%meta_options )->($cmdline);
}

1;
__END__

=head1 DESCRIPTION
 This command-line interface helps the Liberty CCDC Team to troubleshoot Linux systems.

=head1 USAGE


=head1 AUTHOR
 Judah Sotomayor
