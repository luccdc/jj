package LUCCDC::Jiujitsu::Util::Linux::Files;
use strictures 2;
use parent qw(Exporter);
use Symbol qw( gensym );

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(fgrep_flat fgrep slurp_to_array);
%EXPORT_TAGS = (
  DEFAULT => \@EXPORT_OK,

  #patterns => [qw(number_pat string_pat)]
);

# Mostly stolen from File::Grep
sub _fgrep_process {
  my ( $closure, @files ) = @_;
  my $openfile = 0;
  my $abort    = 0;

  for my $i ( 0 .. $#files ) {
    open my $file, '<', $files[$i] or die "Can't open '$files[$i]'";

    while ( my $line = <$file> ) {
      my $state = &$closure( $i, $., $line );
      if ( $state < 0 ) {

        # Shut down search
        $abort = 1;
        last;
      }
      elsif ( $state == 0 ) {
        $abort = 0;
        last;
      }
    }

    close $file or die "Can't close '$files[$i]'";
    last if ($abort);
  }
  return;
}

# Mostly stolen from File::Grep
sub fgrep (&@) {
  my ( $coderef, @files ) = @_;

  if (wantarray) {    # Yield list of matches

    my @matches = map { { filename => $_, count => 0, matches => {} } } @files;

    my $closure = sub {
      my ( $file, $pos, $line ) = @_;
      local $_ = $line;
      if ( &$coderef( $file, $pos, $_ ) ) {
        $matches[$file]->{count}++;
        $matches[$file]->{matches}->{$pos} = $line;
        print $file, "\n";
      }
      return 1;
    };

    _fgrep_process( $closure, @files );
    return @matches;

  }
  elsif ( defined(wantarray) ) {    # Yield count
    my $count   = 0;
    my $closure = sub {
      my ( $file, $pos, $line ) = @_;
      local $_ = $line;
      if ( &$coderef( $file, $pos, $_ ) ) {
        $count++;
      }
      return 1;
    };

    _fgrep_process( $closure, @files );
    return $count;
  }
  else {    # Yield true or false
    my $result  = 0;
    my $closure = sub {
      my ( $file, $pos, $line ) = @_;
      local $_ = $line;
      if ( &$coderef( $file, $pos, $_ ) ) {
        $result = 1;
      }
      return 1;
    };
    return $result;
  }

  return;
}

# Straight stolen from File::Grep
sub fgrep_flat (&@) {
  my ( $coderef, @files ) = @_;
  my @matches;
  my $sub = sub {
    my ( $file, $pos, $line ) = @_;
    local $_ = $line;
    my @nm = &$coderef( $file, $pos, $_ );
    if (@nm) {
      for my $m (@nm) {
        push @matches, $m;
      }
      return 1;
    }
  };
  _fgrep_process( $sub, @files );
  return @matches;
}

sub slurp_to_array {
  my ($filename) = @_;

  open my $file2, '<', $filename or die "Can't open '$filename'";
  my @array = <$file2>;

  close $file2;
  return @array;
}

1;
