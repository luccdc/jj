package LUCCDC::Jiujitsu::Util::Arguments;
use strictures 2;
use parent qw(Exporter);

use LUCCDC::Jiujitsu::Util::Logging;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(parser number_pat string_pat);
%EXPORT_TAGS = (
    DEFAULT  => \@EXPORT_OK,
    patterns => [qw(number_pat string_pat)]

    #Both    => [qw(&func1 &func2)]
);

# TODO Enable during testing VVV

sub number_pat {
    return qr/ ([0-9]*) /xms;
}

sub string_pat {
    return qr/ (\S*) /xms;
}

sub parser {

    # Initialize hash for arguments
    my ( $options_ref, $subcommand_ref, ) = @_;
    my @options    = @{$options_ref};
    my %subcommand = %{$subcommand_ref};

    my %arg = map { $_->{name} => $_->{val} } @options;

    # Master regex for meta and subcommands
    my $subcommand_pat = join '|', reverse sort keys %subcommand;

    my $parse = sub {
        my ($cmdline) = @_;
        pos $cmdline = 0;

      ARG:
        while ( pos $cmdline < length $cmdline ) {

            # Attempt to match a meta option or subcommand.
            if ( my ($subcmd) = $cmdline =~ m/^ \s* ($subcommand_pat)\b /gcxms )
            {
                $subcommand{$subcmd}->( substr( $cmdline, pos($cmdline) ) );
                return;
            }

            # Attempt to match an option
            for my $opt_ref (@options) {
                if ( my ($val) =
                    $cmdline =~
m/\G \s* (?: $opt_ref->{flag} ) \s* =? \s* $opt_ref->{pat} /gcxms
                  )
                {
                    # And, if so, storing the value and moving on...
                    die error(
"Mismatched argument type for option $opt_ref->{name}.\nArgument must match $opt_ref->{pat}."
                    ) unless $val;
                    $arg{ $opt_ref->{name} } = $val;
                    next ARG;
                }
            }

            # Report unknown flags.
            my ($unknown) = $cmdline =~ m/ \s* (\S*) /xms;
            die error("Unknown cmdline flag: $unknown");
        }

        return %arg;
    };

    return $parse;
}

1;
