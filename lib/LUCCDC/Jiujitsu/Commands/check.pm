package LUCCDC::Jiujitsu::Commands::check;
use strictures 2;

use LUCCDC::Jiujitsu::Util::Check     qw(run_cli_check);
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser);

use LUCCDC::Jiujitsu::Checks::ssh qw(%SSH_CHECK);

my %subcommands = ( 'ssh' => sub { run_cli_check \%SSH_CHECK; } );

my @options = ();

sub run {
    my ($cmdline) = @_;

    parser( \@options, \%subcommands )->($cmdline);

    exit;
}

1;
