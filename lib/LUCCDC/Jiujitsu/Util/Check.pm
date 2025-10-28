package LUCCDC::Jiujitsu::Util::Check;
use strictures 2;
use parent qw(Exporter);

# What is a "check"?
# A check is a hash map with the following properties:
# - name: Name of the step, used to look for configuration options
# - checks: A list of check steps
#
# A check step is a subroutine that returns a hash map of three values:
# - status: CHECK_SUCCESS, CHECK_NOT_RUN, CHECK_FAILURE
# - description: Log item to indicate problem
# - details: Hash map of more details of the issue
#
# `run_complete_check` is intended to be passed such a list, and run
# through the steps until it indicates a failure or completes. It will then
# return the results in their entirety
#
# `run_cli_check` is intended to be used in CLI commands to print
# the results of a check as it is performed to stdout
#
# Checks read in data from 3 places:
# - CLI arguments
# - Environment variables
# - A configuration file specified by CLI argument
# This is to allow for 2 things:
# - Persistent configuration and easier editing for repeat runs or the daemon
# - Halt on a signal value, e.g. :STDIN: and read it from stdin or :FILE:/path
#     and read from the file to avoid leaving passwords in CLI arguments or
#     frequently accessed configuration files
#
# To accomplish this, `load_argument` can be used and specify the name and type
# of argument. In the context of a check named "ssh", example invocations of
# `load_argument` are:
#
# <code>
#   load_argument "user", { val => "root" };
#   load_argument "host";
#   load_argument "port", { type => "number" };
# </code>
#
# The first example will first look in the following places for a value:
# - `--ssh-user` CLI argument
# - `JJ_SSH_USER` environment variable
# - `ssh.user` in the specified configuration file as a command line argument
# - The static value `root`
#
# The configuration file format will follow ini formatting, and the path to it
# can be specified with --conf=file, but by default this module will look for
# jj.ini in the current directory
#
# The `conf` section (e.g., --conf-file, JJ_CONF_SHOW_SUCCESSFUL_STEPS) will
# generally dictate how `run_cli_check` and `run_complete_check` work

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION = 1.00;
@EXPORT_OK =
  qw(load_argument run_complete_check run_cli_check check_succeed check_not_run check_fail CHECK_SUCCESS CHECK_NOT_RUN CHECK_FAILURE);
%EXPORT_TAGS = (
    DEFAULT  => \@EXPORT_OK,
    status   => [qw(CHECK_SUCCESS CHECK_NOT_RUN CHECK_FAILURE)],
    statusfn => [qw(check_succeed check_not_run check_fail)],
);

use LUCCDC::Jiujitsu::Util::Logging qw(%CR);

my $CHECK_SUCCESS = "success";
my $CHECK_NOT_RUN = "notrun";
my $CHECK_FAILURE = "failure";

my $options_parsed = 0;
my %current_check;
my %cli_conf;
my %file_conf;

sub check_succeed {
    my ( $desc, $details ) = @_;

    return {
        status      => $CHECK_SUCCESS,
        description => $desc,
        details     => $details
    };
}

sub check_not_run {
    my ( $desc, $details ) = @_;

    return {
        status      => $CHECK_NOT_RUN,
        description => $desc,
        details     => $details
    };
}

sub check_fail {
    my ( $desc, $details ) = @_;

    return {
        status      => $CHECK_FAILURE,
        description => $desc,
        details     => $details
    };
}

sub load_value {
    my ( $key, $value, $args ) = @_;
    my %val_args = %{$args};

    if ( $value eq ":STDIN:" ) {
        `stty -echo`;
        print "Enter a value for the following - ${current_check{name}}.$key: ";
        $value = <STDIN>;
        `stty echo`;
        chomp $value;
        print "\n";
    }
    elsif ( $value =~ m{:FILE:(.*)}xms ) {
        open my $fh, '<', $1 or return "";
        $value = <$fh>;
        chomp $value;
        close $fh;
    }
    return $value;
}

sub load_config_value {
    my ( $check_name, $key, $args_ref ) = @_;
    my %empty = ();
    $args_ref ||= \%empty;

    if ( $cli_conf{"$check_name-$key"} ) {
        return load_value( $key, $cli_conf{"$check_name-$key"}, $args_ref );
    }

    my $env_check_name = $check_name;
    $env_check_name =~ s/-/_/;
    my $var_name = uc("JJ_${env_check_name}_$key");

    if ( $ENV{$var_name} ) {
        return load_value( $key, $ENV{$var_name}, $args_ref );
    }

    if (   $file_conf{ $current_check{"name"} }
        && $file_conf{ $current_check{"name"} }->{$key} )
    {
        return load_value( $key, $file_conf{ $current_check{"name"} }->{$key},
            $args_ref );
    }

    if ( $args_ref->{"val"} ) {
        return load_value( $key, $args_ref->{"val"}, $args_ref );
    }

    return;
}

sub load_argument {
    my ( $key, $args_ref ) = @_;
    return load_config_value( $current_check{"name"}, $key, $args_ref );
}

sub load_ini {
    my ($ini_path) = @_;
    my $section = "conf";
    open my $ini, '<', $ini_path or die "Can't open $ini_path: $!\n";
    while (<$ini>) {
        chomp;
        if (/^\s*\[([^\[]+)]/xms) {
            $section = $1;
        }
        if (/^\s*([^=]*?)\s*=\s*(.+?)\s*$/xms) {
            $file_conf{$section}->{$1} = $2;
        }
    }
    close $ini;
    return;
}

sub parse_options {
    my @args = @ARGV;

    while ( defined( my $arg = shift @args ) ) {
      ARG_PARSE:
        if ( $arg =~ qr/^--[^=]+=/xms ) {
            my ( $key, $val ) = $arg =~ m/^--([^=]+)=(.*)/xms;
            $key =~ s/^--//;
            $cli_conf{$key} = $val;
        }
        elsif ( $arg =~ qr/^--/xms ) {
            my $key = $arg;
            $key =~ s/^--//;

            $arg = shift @args;

            if ( !defined($arg) ) {
                $cli_conf{$key} = 1;
                next;
            }

            if ( $arg =~ qr/^--/ ) {
                $cli_conf{$key} = 1;
                goto ARG_PARSE;
            }

            $cli_conf{$key} = $arg;
        }
    }

    if ( $cli_conf{"conf-file"} ) {
        load_ini $cli_conf{"conf-file"};
    }

    $options_parsed = 1;

    return;
}

sub run_complete_check {
    my ($check_ref) = @_;

    %current_check = %{$check_ref};

    parse_options if !$options_parsed;

    return;
}

sub run_cli_check {
    my ($check_ref) = @_;

    %current_check = %{$check_ref};

    parse_options;

    my $hide_successful_steps = load_config_value "conf",
      "hide-successful-steps";

    my $show_not_run_steps = load_config_value "conf", "show-not-run-steps";

    my @checks     = @{ $current_check{"checks"} };
    my $check_name = $current_check{"name"};

    foreach my $check (@checks) {
        my $check_value = $check->();

        if ( $check_value->{"status"} eq $CHECK_SUCCESS ) {
            next if $hide_successful_steps;

            print $CR{"green"}, "[$check_name] Check succeeds: ",
              $check_value->{"description"}, $CR{"nocolor"};
        }
        elsif ( $check_value->{"status"} eq $CHECK_NOT_RUN ) {
            next if !$show_not_run_steps;

            print $CR{"magenta"}, "[$check_name] Check not run: ",
              $check_value->{"description"}, $CR{"nocolor"};
        }
        elsif ( $check_value->{"status"} eq $CHECK_FAILURE ) {
            print $CR{"red"}, "[$check_name] Check failed! ",
              $check_value->{"description"},
              $CR{"nocolor"};
        }

        print "\n\n";

        if ( keys %{ $check_value->{"details"} } ) {
            print "Extra check details:\n";

            while ( my ( $k, $v ) = each %{ $check_value->{"details"} } ) {
                print "\t$k:\t$v\n";
            }

            print "\n";
        }

        if ( $check_value->{"status"} eq $CHECK_FAILURE ) {
            return;
        }
    }

    print $CR{"green"}, "[$check_name] All checks pass!\n", $CR{"nocolor"};

    return;
}

1;
