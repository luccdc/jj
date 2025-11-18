package LUCCDC::Jiujitsu::Util::Check;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(%SSH_CHECK);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT_OK );

1;
