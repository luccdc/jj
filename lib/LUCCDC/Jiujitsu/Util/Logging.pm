package LUCCDC::Jiujitsu::Util::Logging;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(error warning message %CR);
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

sub error {
    my ($message) = @_;
    return $CR{red} . $message . $CR{nocolor};

}

sub warning {
    my ($message) = @_;
    return $CR{yellow} . $message . $CR{nocolor};

}

sub message {
    my ($message) = @_;
    return $message;

}

1;
