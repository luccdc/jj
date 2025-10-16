package LUCCDC::Jiujitsu::Util::Regex;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(%RX);
%EXPORT_TAGS = (
    DEFAULT => \@EXPORT_OK,

    #patterns => [qw(number_pat string_pat)]
);

our %RX = (
    dec  => qr/[0-9]+/x,
    hex  => qr/[0-9A-F]+/x,
    hex8 => qr/[0-9A-F]{8}/x,
    hex4 => qr/[0-9A-F]{4}/x,
    hex2 => qr/[0-9A-F]{2}/x,
);

1;
