package LUCCDC::Jiujitsu::Commands::file;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging   qw(error warning %CR);
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);
use Digest::SHA;
use Cwd 'abs_path';
use POSIX;
use Carp;

my @options = (
    {
        name => 'files',
        flag => '--files|-f',
        val  => [],
        type => 'list',
    },
    {
        name => 'dirs',
        flag => '--dirs|-d',
        val  => [],
        type => 'list',
    },
    {
        name => 'hashfile',
        flag => '--hashfile|-h',
        val  => './jj_hashes.txt',
        type => 'string',
    },
    {
        name => 'recursive',
        flag => '--recursive|-r',
        val  => 0,
        type => 'flag',
    },
    {
        name => 'all',
        flag => '--all|-a',
        val  => 0,
        type => 'flag',
    },
    {
        name => 'short',
        flag => '--short|-s',
        val  => 0,
        type => 'flag',
    },
);

my %subcommands = (
    'store-hashes'  => \&store,
    's'             => \&store,
    'verify-hashes' => \&verify,
    'v'             => \&verify,
    '--help'        => \&help,
);

my $toplevel_parser = parser( \@options, \%subcommands );
my $subcmd_parser   = parser( \@options, {} );

sub run {
    my @cmdline = @_;
    my %arg     = $toplevel_parser->(@cmdline);
    help();
    exit;
}

sub store {
    my @cmdline = @_;
    my %arg     = $subcmd_parser->(@cmdline);

    if ( $arg{'files'} eq '' && $arg{'dirs'} eq '' ) {
        croak warning('No files specified');
    }

    open my $hashfile, '>', $arg{'hashfile'}
      or croak error('Invalid hash file');
    store_hashes( $hashfile, get_files(%arg) );
    close $hashfile;

    exit;
}

sub store_hashes {
    my ( $hashfile, @files ) = @_;
    for my $file (@files) {
        if ( -f $file ) {
            my $sha1 = Digest::SHA->new(256);
            $sha1->addfile($file);

            my $dir      = getcwd;
            my $abs_path = abs_path($file);
            my $time     = strftime '%Y-%m-%d %H:%M:%S', localtime time;

            print $hashfile $abs_path, ' ', $sha1->hexdigest, ' ', $time, "\n";
            print $abs_path,           ' ', $sha1->hexdigest, ' ', $time, "\n";
        }
    }
    return;
}

sub verify {

    my @cmdline = @_;
    my %arg     = $subcmd_parser->(@cmdline);

    my $path_to_hash = sub {
        if   ( -d $_ ) { return $_ => 'dir' }
        else           { return $_ => 'file' }
    };
    my %tracked_paths = map { $path_to_hash->($_) } get_files(%arg);
    my @data_to_verify;

    open my $hashfile, '<', $arg{'hashfile'}
      or croak error('Invalid hash file');
    retrieve_hashes( $hashfile, \@data_to_verify, %tracked_paths );
    close $hashfile;

    # Verify each file
    foreach my $line (@data_to_verify) {
        my @data     = split / /, $line;
        my $filepath = $data[0];
        my $hash     = $data[1];
        my $time     = $data[2];

        next
          if ( exists( $tracked_paths{$filepath} )
            && $tracked_paths{$filepath} eq 'dir' );
        if ( -f $filepath ) {
            my $sha1 = Digest::SHA->new(256);
            $sha1->addfile($filepath);

            if ( $hash eq $sha1->hexdigest ) {
                if ( !$arg{'short'} ) {
                    print "[$CR{green}✓$CR{nocolor}]: $filepath\n";
                }
            }
            elsif ( -l $filepath ) {
                if ( !$arg{'short'} ) {
                    print "[$CR{cyan}s$CR{nocolor}]: $filepath\n";
                }
            }
            elsif ( $hash eq '?' ) {
                print
"[$CR{yellow}!$CR{nocolor}]: $CR{yellow}$filepath$CR{nocolor}\n";
            }
            else {
                print
                  "[$CR{red}✗$CR{nocolor}]: $CR{red}$filepath$CR{nocolor}\n";
            }
        }
        else {
            print
              "[$CR{yellow}?$CR{nocolor}]: $CR{yellow}$filepath$CR{nocolor}\n";
        }
    }

    exit;
}

sub retrieve_hashes {
    my ( $hashfile, $data_to_verify_p, %tracked_paths ) = @_;
    my %known_paths = %tracked_paths;
    while ( my $line = <$hashfile> ) {

        my @data     = split / /, $line;
        my $filepath = $data[0];
        my $hash     = $data[1];
        my $time     = $data[2];

        if ( ( keys %tracked_paths ) == 0 ) {
            push @{$data_to_verify_p}, $line;
            delete %known_paths{$filepath};
        }
        elsif ( exists $tracked_paths{$filepath} ) {
            push @{$data_to_verify_p}, $line;
            delete %known_paths{$filepath};
        }
        elsif ( $filepath =~ /(.*)\/([^\/]*)/x && exists $tracked_paths{$1} ) {
            my $dir = $1;
            push @{$data_to_verify_p}, $line;
            delete %known_paths{$filepath};
        }
    }
    for my $path ( keys %known_paths ) {
        if ( $known_paths{$path} eq 'file' ) {
            push @{$data_to_verify_p}, "$path ? ?";
        }
    }
    return;
}

sub help {

    print <<"END_HELP";
Tools for files

Usage:
	jj file <subcommand> <options>

Subcommands:
	s, store-hashes:  Stores current hashes
	v, verify-hashes: Verifies stored hashes

Verification Status:
	[$CR{green}✓$CR{nocolor}]: Good hash
	[$CR{red}✗$CR{nocolor}]: Bad hash
	[$CR{yellow}?$CR{nocolor}]: Missing file
	[$CR{yellow}!$CR{nocolor}]: Unhashed file
	[$CR{cyan}s$CR{nocolor}]: Symlink

Options:
	-f, --files=FILES     Comma separated list of files to examine.
	-d, --dirs=DIRS       Comma separated list of directories to examine.
	-h, --hashfile=FILE   Location of stored hashes (default ./jj_hashes.txt).
	-r, --recursive       Enables recursion on specified directories.
	-a, --all             Include hidden files and directories
	-s, --short           Do not print valid hashes during verification

END_HELP

    exit;
}

sub get_files {
    my (%arg) = @_;

    my @tracked_paths = ();
    my $recursive     = $arg{"recursive"};
    my $show_hidden   = $arg{"all"};

    # Parse files to check
    my @files = @{ $arg{"files"} };
    for my $file (@files) {
        my $abs_path = abs_path($file);
        push_file( $abs_path, \@tracked_paths );
    }

    # Parse dirs to check
    my @dirs = @{ $arg{"dirs"} };
    for my $dir (@dirs) {
        my $abs_path = abs_path($dir);
        push_dir( $abs_path, \@tracked_paths, $recursive, $show_hidden );
    }

    return @tracked_paths;
}

sub push_file {
    my ( $file, $tracked_paths_pointer ) = @_;
    push @{$tracked_paths_pointer}, $file;
    return;
}

sub push_dir {
    my ( $dir, $tracked_paths_pointer, $recursive, $show_hidden ) = @_;

    opendir( my $dir_pointer, $dir )
      or croak error("Invalid directory: $dir\n");
    push @{$tracked_paths_pointer}, $dir;
    my @files = readdir $dir_pointer;
    closedir $dir_pointer;

    foreach my $entry (@files) {

        # skip . and ..
        next if ( $entry                         =~ /^[.]+$/smx );
        next if ( ( not $show_hidden ) && $entry =~ /^[.].+$/smx );

        my $entry_abs_path = "$dir/$entry";

        if ( -f $entry_abs_path ) {
            push_file( $entry_abs_path, $tracked_paths_pointer );
        }
        elsif ( -d $entry_abs_path && $recursive ) {
            push_dir( $entry_abs_path, $tracked_paths_pointer, $recursive,
                $show_hidden );
        }
    }
    return;
}

1;
