package LUCCDC::Jiujitsu::Util::Logging;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(use_buffer get_buffer error warning message header %CR);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT_OK, );

our %CR = (
    black   => "\033[0;30m",
    red     => "\033[0;31m",
    green   => "\033[0;32m",
    yellow  => "\033[0;33m",
    blue    => "\033[0;34m",
    magenta => "\033[0;35m",
    cyan    => "\033[0;36m",
    white   => "\033[0;37m",
    nocolor => "\033[0m",
);

my $USE_BUFFER = 0;
my @BUFFER     = ();

sub use_buffer {
    $USE_BUFFER = 1;
    @BUFFER     = ();

    return;
}

sub get_buffer {
    my @local_buffer = @BUFFER;
    @BUFFER     = ();
    $USE_BUFFER = 0;

    return @local_buffer;
}

sub header {
    my ( $message, $header ) = @_;
    $header ||= "--- ";

    if ($USE_BUFFER) {
        my %msg = (
            class   => "header",
            message => $message
        );
        push @BUFFER, ( \%msg );
    }
    else {
        print $CR{green}, $header, $message, $CR{nocolor};
    }

    return;
}

sub error {
    my ($message) = @_;

    if ($USE_BUFFER) {
        my %msg = (
            class   => "error",
            message => $message
        );
        push @BUFFER, ( \%msg );
    }
    else {
        print $CR{red}, $message, $CR{nocolor};
    }

    return;
}

sub warning {
    my ($message) = @_;

    if ($USE_BUFFER) {
        my %msg = (
            class   => "warning",
            message => $message
        );
        push @BUFFER, ( \%msg );
    }
    else {
        print $CR{yellow}, $message, $CR{nocolor};
    }

    return;
}

sub message {
    my ($message) = @_;

    if ($USE_BUFFER) {
        my %msg = (
            class   => "message",
            message => $message
        );
        push @BUFFER, ( \%msg );
    }
    else {
        print $message;
    }

    return;
}

1;
