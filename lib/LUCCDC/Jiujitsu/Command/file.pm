package LUCCDC::Jiujitsu::Command::file;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use LUCCDC::Jiujitsu::Util::Logging          qw(error warning %CR);
use LUCCDC::Jiujitsu::Util::Linux::Files     qw(dirmap);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(platform);
use Digest::SHA;
use Cwd 'abs_path';
use POSIX;
use Carp;

sub abstract { "Tools for files" }

sub usage_desc { "$0 file <command> %o <files>" }

sub description {
    chomp( my $s = <<"EODESC");
Subcommands:
	s, store-hashes:     Stores current hashes
	v, verify-hashes:    Verifies stored hashes
	vp, verify-packages: Verifies installed packages

Verification Status:
	[$CR{green}✓$CR{nocolor}]: Good\t[$CR{red}✗$CR{nocolor}]: Bad
	[$CR{yellow}?$CR{nocolor}]: Missing\t[$CR{yellow}!$CR{nocolor}]: Unhashed
	[$CR{cyan}s$CR{nocolor}]: Symlink

Options:
EODESC

    return $s;
}

sub opt_spec {
    return (
        [
            'hashfile|H=s',
            "Location of stored hashes.",
            { default => './jj_hashes.txt' }
        ],
        [ 'recursive|r', 'Enable recursion into directories.', ],
        [ 'all|a',       'Include hidden files and directories.' ],
        [ 'short|s',     'Do not print valid hashes during verification.' ]
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    my ( $cmd, @paths ) = @{$args};
    croak "Missing cmomand!" unless $cmd;
    if ( $cmd eq 'v' or $cmd eq 'verify-hashes' ) {
        verify( $opt, \@paths );
    }
    elsif ( $cmd eq 's' or $cmd eq 'store-hashes' ) {
        croak warning('No paths specified') unless @paths;
        store( $opt, \@paths );
    }
    elsif ( $cmd eq 'vp' or $cmd eq 'verify-packages' ) {
        verify_pkgs();
    }
    else {
        croak "Invalid command: $cmd";
    }
}

sub execute {
    my ( $self, $opt, $args ) = @_;
    exit;
}

sub store {
    my ( $opt, $paths ) = @_;

    open my $hashfile, '>', $opt->{hashfile}
      or croak error('Invalid hash file');
    store_hashes( $hashfile, get_files( $opt, $paths ) );
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
    my ( $opt, $paths ) = @_;

    my $path_to_hash = sub {
        if   ( -d $_ ) { return $_ => 'dir' }
        else           { return $_ => 'file' }
    };
    my %tracked_paths = map { $path_to_hash->($_) } get_files( $opt, $paths );
    my @data_to_verify;

    open my $hashfile, '<', $opt->{hashfile}
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
                if ( !$opt->{short} ) {
                    print "[$CR{green}✓$CR{nocolor}]: $filepath\n";
                }
            }
            elsif ( -l $filepath ) {
                if ( !$opt->{short} ) {
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

sub verify_pkgs {
    my @target_dirs = ( '/usr/bin', '/usr/sbin' );
    push @target_dirs, ( '/bin', '/sbin' ) unless ( -l "/bin" );

    my $verify_f;
    my $filecount = 0;

    if ( platform() eq "rhel" ) {
        my $verify_output = `rpm -Va 2>&1`;
        if ($verify_output) {
            print "rpm -Va output: \n";
            print $verify_output;
        }

        $verify_f = sub {
            my ($file) = @_;
            $filecount++;
            system("rpm -qf \"$file\" >/dev/null 2>&1");
            if ( $? != 0 ) {
                print "[$CR{yellow}!$CR{nocolor}]: $file (UNOWNED)\n";
            }
        }
    }
    else {
        my %packages_checked;
        $verify_f = sub {
            my ($file) = @_;
            $filecount++;
            my $package;
            if ( `dpkg -S $file 2>/dev/null` =~ /^([a-z0-9][a-z0-9.+-]+):/ ) {
                $package = $1;
                unless ( $packages_checked{$package} ) {
                    $packages_checked{$package} = 1;
                    `dpkg -V "$package" 2>&1`;
                }

            }
            else {
                print "[$CR{yellow}!$CR{nocolor}]: $file (UNOWNED)\n";
            }

        }
    }

    for my $dir (@target_dirs) {
        print "Scanning $dir...\n";
        dirmap( $dir, $verify_f );
    }
    exit;
}

sub get_files {
    my ( $opt, $paths ) = @_;

    my @tracked_paths = ();
    my $recursive     = $opt->{recursive};
    my $show_hidden   = $opt->{all};

    # Parse files to check
    for my $path ( @{$paths} ) {
        if ( -f $path ) {
            my $abs_path = abs_path($path);
            push_file( $abs_path, \@tracked_paths );
        }
        elsif ( -d $path ) {
            my $abs_path = abs_path($path);
            push_dir( $abs_path, \@tracked_paths, $recursive, $show_hidden );
        }
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
