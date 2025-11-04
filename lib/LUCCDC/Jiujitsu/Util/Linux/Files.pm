package LUCCDC::Jiujitsu::Util::Linux::Files;
use strictures 2;
use parent qw(Exporter);
use Symbol qw( gensym );
use Carp qw(croak);
use Cwd qw(abs_path);
use File::Spec;

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(fgrep_flat fgrep slurp_to_array dirmap);
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
sub fgrep (&@) {    ## no critic (ProhibitSubroutinePrototypes)
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
sub fgrep_flat (&@) {    ## no critic (ProhibitSubroutinePrototypes)
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

sub dirmap {
	my ( $start_dir, $filter_func, $p_recurse, $p_max_depth, $p_follow_symlinks) = @_;

	croak "Starting directory not provided" unless defined $start_dir;
	croak "Filter function not provided" unless defined $filter_func;
	croak "Filter function is not a code reference" if ref($filter_func) ne 'CODE';
	
	my $recurse = $p_recurse // 1;
	my $max_depth = $p_max_depth // -1;
	my $follow_symlinks = $p_follow_symlinks // 0;

	my $abs_start_dir = abs_path($start_dir);
	croak "Directory '$start_dir' does not exist or is not a directory" unless defined $abs_start_dir && -d $abs_start_dir;

	my @found_files;
	_traverse( $abs_start_dir, $filter_func, $recurse, 0, $max_depth, $follow_symlinks, \@found_files );

	return @found_files;
}

sub _traverse {
	my ( $current_dir, $filter_func, $recurse, $current_depth, $max_depth, $follow_symlinks, $results_ref ) = @_;

	return if ( $max_depth != -1 && $current_depth > $max_depth );

	my $dh;
	unless ( opendir( $dh, $current_dir ) ) {
		warn "Could not open directory '$current_dir' : $!";
		return;
	}

	while ( my $entry = readdir($dh) ) {
		next if $entry eq '.' or $entry eq '..';

		my $full_path = File::Spec->catfile( $current_dir, $entry );

		if ( !( -l $full_path ) || $follow_symlinks ) {
			if ( -d $full_path ) {
				if ($recurse) {
					_traverse( $full_path, $filter_func, $recurse, $current_depth + 1, $max_depth, $follow_symlinks, $results_ref );
				}
			}
			elsif ( -f $full_path ) {
				if ( $filter_func->($full_path) ) {
					push @{$results_ref}, $full_path;
				}
			}
		}
	}

	closedir($dh);
}

1;
