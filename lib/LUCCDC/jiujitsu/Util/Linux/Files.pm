package LUCCDC::jiujitsu::Util::Linux::Files;
use Symbol qw( gensym );

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(fgrep);
%EXPORT_TAGS = (
  DEFAULT => \@EXPORT_OK,

  #patterns => [qw(number_pat string_pat)]
);

sub fgrep {
  my ( $filename, $regex ) = @_;

  my $file = gensym();

  open $file, '<', $filename
    or die "Can't open '$filename': $OS_ERROR";

}
