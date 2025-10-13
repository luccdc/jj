package LUCCDC::jiujitsu::Util::Linux::Files;
use Symbol qw( gensym );

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(fgrep slurp_to_array);
%EXPORT_TAGS = (
  DEFAULT => \@EXPORT_OK,

  #patterns => [qw(number_pat string_pat)]
);

sub fgrep {
  my ( $filename, $regex ) = @_;

  my $file = gensym();

  open $file, '<', $filename
    or die "Can't open '$filename'";

  for my $line (<$file>) {
    if ( $line =~ $regex ) {
      return $line;
    }
  }
}

sub slurp_to_array {
  my ($filename) = @_;

  my $file = gensym();
  open $file, $filename;

  my @array = <$file>;

  return @array;
}
