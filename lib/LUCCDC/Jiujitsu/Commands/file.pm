package LUCCDC::Jiujitsu::Commands::file;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging qw(error warning);
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser :patterns);
use Digest::SHA;
use Cwd 'abs_path';
use POSIX;
use Carp;

my $black   = "\033[0;30m";
my $red     = "\033[0;31m";
my $green   = "\033[0;32m";
my $yellow  = "\033[0;33m";
my $white   = "\033[0;37m";
my $nocolor = "\033[0m";

my @options = (
    {
        name => 'files',
        flag => '--files|-f',
        val  => "",
        pat  => string_pat,
    },
    {
        name => 'dirs',
        flag => '--dirs|-d',
        val  => '',
        pat  => string_pat,
    },
    {
        name => 'hashfile',
        flag => '--hashfile|-h',
        val  => './jj_hashes.txt',
        pat  => string_pat,
    },
    {
        name => 'recursive',
        flag => '--recursive|-r',
        val  => 0,
        pat  => flag_pat,
    },
    {
        name => 'all',
        flag => '--all|-a',
        val  => 0,
        pat  => flag_pat,
    },
);

my %subcommands = ( 
    'store-hashes' => \&store,
    's' => \&store,
    'verify-hashes' => \&verify,
    'v' => \&verify,
    '--help' => \&help,
);
my %empty = ();

my $toplevel_parser = parser( \@options, \%subcommands );
my $subcmd_parser   = parser( \@options, \%empty );

sub run {
    my ($cmdline) = @_;
    my %arg = $toplevel_parser->($cmdline);
    help();
    exit;
}

sub store {
    my ($cmdline) = @_;
    my %arg = $subcmd_parser->($cmdline);

    if($arg{'files'} eq '' && $arg{'dirs'} eq '') {
        croak warning('No files specified')
    }

    open my $hashfile, '>', $arg{'hashfile'} or croak error('Invalid hash file');

    for my $file ( get_files(%arg) ) {
        my $sha1 = Digest::SHA->new(256);
        $sha1->addfile($file);

        my $dir = getcwd;
        my $abs_path = abs_path($file);

        my $time = strftime '%Y-%m-%d %H:%M:%S', localtime time;

        print $hashfile $abs_path, ' ',  $sha1->hexdigest, ' ', $time, "\n";
        print $abs_path, ' ',  $sha1->hexdigest, ' ', $time, "\n";
    }

    close $hashfile;

    exit;
}

sub verify {

    my ($cmdline) = @_;
    my %arg = $subcmd_parser->($cmdline);

    open my $hashfile, '<', $arg{'hashfile'} or croak error('Invalid hash file');

    my %tracked_paths = map { $_ => 1 } get_files(%arg);
    my @data_to_verify;

    # Load file hashes
    while(my $line = <$hashfile>) {

        my @data = split / /, $line ;
        my $filepath = $data[0];
        my $hash = $data[1];
        my $time = $data[2];

        if((keys %tracked_paths) == 0) {
            push @data_to_verify, $line;
        }
        elsif(exists $tracked_paths{$filepath}){
            push @data_to_verify, $line;
        }
    }

    close $hashfile;

    # Verify each file
    foreach my $line ( @data_to_verify ) {
        my @data = split / /, $line ;
        my $filepath = $data[0];
        my $hash = $data[1];
        my $time = $data[2];

        if(-f $filepath) {
            my $sha1 = Digest::SHA->new(256);
            $sha1->addfile($filepath);

            if($hash eq $sha1->hexdigest) {
                print "[$green✓$nocolor]: $filepath\n";
            }
            else {
                print "[$red✗$nocolor]: $red$filepath$nocolor\n";
            }
        }
        else {
            print "[$yellow!$nocolor]: $yellow$filepath$nocolor\n";
        }
    }

    exit;
}

sub help {

    print "Tools for files\n";
    print "Usage:\n";
    print "\tjj file <subcommand> <options>\n";
    print "Subcommands:\n";
    print "\tstore-hashes (s): Stores current hashes\n";
    print "\tverify-hashes (v): Verifies stored hashes \n";
    print "\t\t[ ]: Good hash\n";
    print "\t\t[X]: Bad hash\n";
    print "\t\t[!]: Missing file\n";
    print "Options:\n";
    print "\t--files (-f): Comma separated list of files to examine.\n";
    print "\t--dirs (-d): Comma separated list of directories to examine.\n";
    print "\t--hashfile (-h): Location of stored hashes (default ./jj_hashes.txt).\n";
    print "\t--recursive (-r): Enables recursion on specified directories.\n";
    print "\t--all (-a): Include hidden files and directories\n";
    exit;
}

sub get_files {
    my (%arg) = @_;

    my @tracked_paths=();
    my $recursive = $arg{"recursive"};
    my $show_hidden = $arg{"all"};
    
    # Parse files to check
    my @files = split /,/x, $arg{"files"};
    for my $file ( @files ) {
        my $abs_path = abs_path($file);
        push_file($abs_path, \@tracked_paths);
    }

    # Parse dirs to check
    my @dirs = split /,/x, $arg{"dirs"};
    for my $dir ( @dirs ) {
        my $abs_path = abs_path($dir);
        push_dir($abs_path, \@tracked_paths, $recursive, $show_hidden);
    }

    return @tracked_paths;
}

sub push_file {
    my ($file, $tracked_paths_pointer)  = @_;
    push @{$tracked_paths_pointer}, $file;
    return;
}

sub push_dir {
    my ($dir, $tracked_paths_pointer, $recursive, $show_hidden) = @_;

    opendir(my $dir_pointer, $dir);
    my @files = readdir $dir_pointer;
    closedir $dir_pointer;

    foreach my $entry (@files)
    {
        # skip . and ..
        next if($entry =~ /^[.]+$/smx);
        next if((not $show_hidden) && $entry =~ /^[.].+$/smx);

        my $entry_abs_path = "$dir/$entry";

        if(-f $entry_abs_path){
            push_file($entry_abs_path, $tracked_paths_pointer);
        }
        elsif(-d $entry_abs_path && $recursive){
            push_dir($entry_abs_path, $tracked_paths_pointer, $recursive, $show_hidden);
        }
    }
    return;
}

1;
