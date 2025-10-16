package LUCCDC::Jiujitsu::Util::Linux::Files;
use strictures 2;
use parent qw(Exporter);
use Symbol qw( gensym );

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
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
  my @lines = <$file>;
  close $file or die "Can't close '$filename'";

  for my $line (@lines) {
    if ( $line =~ $regex ) {
      return $line;
    }
  }
  return;
}

sub slurp_to_array {
  my ($filename) = @_;

  open my $file2, '<', $filename or die "Can't open '$filename'";
  my @array = <$file2>;

  close $file2;
  return @array;
}

1;
