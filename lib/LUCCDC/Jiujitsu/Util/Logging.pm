package LUCCDC::Jiujitsu::Util::Logging;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(error warning message header %CR);
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

sub header {
    my ( $message, $header ) = @_;
    $header ||= "--- ";

    print $CR{green}, $header, $message, $CR{nocolor};

    return;
}

sub error {
    my ($message) = @_;
    print $CR{red}, $message, $CR{nocolor};

    return;
}

sub warning {
    my ($message) = @_;
    print $CR{yellow}, $message, $CR{nocolor};

    return;
}

sub message {
    my ($message) = @_;
    print $message;

    return;
}

1;
