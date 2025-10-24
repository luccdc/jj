package LUCCDC::Jiujitsu::Util::Arguments;
use strictures 2;
use parent qw(Exporter);
use Carp;

use LUCCDC::Jiujitsu::Util::Logging qw(error);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(parser number_pat string_pat flag_pat);
%EXPORT_TAGS = (
    DEFAULT  => \@EXPORT_OK,
    patterns => [qw(number_pat string_pat flag_pat)]

    #Both    => [qw(&func1 &func2)]
);

sub split_flags {
    my ($flag) = @_;

    if ($flag) {
        return split( /[,=]/, $flag );
    }
    else {
        return "";
    }
}

sub number_pat {
    return qr/ ([0-9]*) /xms;
}

sub string_pat {
    return qr/ (\S*) /xms;
}

sub flag_pat {
    return qr/        /xms;
}

sub extract_option {
    my ( $args_list, $opt_ref ) = @_;

    my $type = $opt_ref->{type};
    my $flag = $opt_ref->{name};

    if ( $type eq "flag" ) {
        return 1;
    }
    elsif ( $type eq "number" ) {
        my $param = shift @{$args_list};
        croak error("Missing argument to $flag flag\n") unless ($param);
        if ( $param =~ number_pat() ) {
            return $param;
        }
        else {
            croak error(
                "Argument provided to $flag flag is not a number: $param\n");
        }
    }
    elsif ( $type eq "string" ) {
        my $param = shift @{$args_list};
        croak error("Missing argument to $flag flag\n") unless ($param);
        return $param;
    }
    elsif ( $type eq "list" ) {
        my @params;
        while ( @{$args_list} and @{$args_list}[0] !~ m/^-/xms ) {
            push( @params, shift @{$args_list} );
        }
        print join( ' ', @params );
        croak error("No arguments provided to $flag flag.\n") unless (@params);
        return \@params;
    }
}

sub parser {

    # Initialize hash for arguments
    my ( $options_ref, $subcommand_ref, ) = @_;
    my @options    = @{$options_ref};
    my %subcommand = %{$subcommand_ref};

    my %arg = map { $_->{name} => $_->{val} } @options;

    # Master regex for meta and subcommands
    my $subcommand_pat = join '|', reverse sort keys %subcommand;
    my $options_pat    = join '|', reverse sort map { $_->{flag} } @options;

    my $parse = sub {
        my @cmdline_list = @_;

        my @args_list = map { split_flags($_) } @cmdline_list;

      ARG:
        while ( my $arg = shift @args_list ) {

            # Attempt to match a meta option or subcommand.
            if ( $arg =~ m/^ \s* ($subcommand_pat)\b /xms ) {
                $subcommand{$arg}->(@args_list);
            }
            else {
                for my $opt_ref (@options) {
                    if ( $arg =~ m/(?:$opt_ref->{flag})/xms ) {
                        if ( $opt_ref->{type} eq "flag" ) {

                        }
                        $arg{ $opt_ref->{name} } =
                          extract_option( \@args_list, $opt_ref );
                        next ARG;
                    }
                }

                croak error("Invalid flag or subcommand: $arg\n");
            }

        }

        return %arg;
    };

    return $parse;
}

1;
