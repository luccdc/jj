package LUCCDC::jiujitsu::Util::Logging;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION = 1.00;
@EXPORT  = qw(error warning message);

#@EXPORT_OK   = qw(error warn log);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT_OK, );

my $black   = "\033[0;30m";
my $red     = "\033[0;31m";
my $green   = "\033[0;32m";
my $yellow  = "\033[0;33m";
my $white   = "\033[0;37m";
my $nocolor = "\033[0m";

sub error {
    my ($message) = @_;
    return $red . $message . $nocolor;

}

sub warning {
    my ($message) = @_;
    return $yellow . $message . $nocolor;

}

sub message {
    my ($message) = @_;
    return $message;

}

1;
