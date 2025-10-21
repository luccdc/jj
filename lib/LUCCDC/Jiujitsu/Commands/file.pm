package LUCCDC::Jiujitsu::Commands::file;
use strictures 2;
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::Arguments    qw(&parser :patterns);
use Digest::SHA;
use Cwd 'abs_path';
use POSIX;

my @options = (
    {
        name => 'files',
        flag => '--files|-f',
        val  => "",
        pat  => string_pat,
    },
    {
        name => 'hashfile',
        flag => '--hashfile|-h',
        val  => "./jj_hashes.txt",
        pat  => string_pat,
    },
);

my %subcommands = ( 
    'store-hashes' => \&store,
    'verify-hashes' => \&verify,
    '--help' => \&help,
);
my %empty = ();

my $toplevel_parser = parser( \@options, \%subcommands );
my $subcmd_parser   = parser( \@options, \%empty );

sub run {
    my ($cmdline) = @_;
    my %arg = $toplevel_parser->($cmdline);
    exit;
}

sub store {
    my ($cmdline) = @_;
    my %arg = $subcmd_parser->($cmdline);

    open(my $hashfile, '>', $arg{"hashfile"}) or die $!;

    for my $file ( split( /,/, $arg{"files"} ) ) {
        my $sha1 = Digest::SHA->new(256);
        $sha1->addfile($file);

        my $dir = getcwd;
        my $abs_path = abs_path($file);

        my $time = strftime "%Y-%m-%d %H:%M:%S", localtime time;

        print $hashfile $abs_path, " ",  $sha1->hexdigest, " ", $time, "\n";
        print $abs_path, " ",  $sha1->hexdigest, " ", $time, "\n";
    }

    close($hashfile);

    exit;
}

sub verify {

    my ($cmdline) = @_;
    my %arg = $subcmd_parser->($cmdline);

    open(my $hashfile, '<', $arg{"hashfile"}) or die $!;
    my @data_to_verify;
    
    while(<$hashfile>) {
        my $line = $_;
        my @data = split( / /, $line );
        my $filepath = $data[0];
        my $hash = $data[1];
        my $time = $data[2];

        if($arg{"files"} eq "") {
            push(@data_to_verify, $line);
        }
        for my $file ( split( /,/, $arg{"files"} ) ) {
            my $dir = getcwd;
            my $abs_path = abs_path($file);
            if($abs_path eq $filepath){
                push(@data_to_verify, $line);
            }
        }
    }

    close($hashfile);

    foreach my $line ( @data_to_verify ) {
        my @data = split( / /, $line );
        my $filepath = $data[0];
        my $hash = $data[1];
        my $time = $data[2];

        
        if(-e $filepath) {
            my $sha1 = Digest::SHA->new(256);
            $sha1->addfile($filepath);

            if($hash eq $sha1->hexdigest) {
                print "[ ]: $filepath\n";
            }
            else {
                print "[X]: $filepath\n";
            }
        }
        else {
            print "[!]: $filepath\n";
        }

    }


    exit;
}

sub help {

    print "Tools for files.\n";
    print "Subcommands:.\n";
    print "\tstore-hashes - Stores current hashes\n";
    print "\tverify-hashes - Verifies stored hashes \n";
    print "\t\t[ ]: Good hash\n";
    print "\t\t[X]: Bad hash\n";
    print "\t\t[!]: Missing file\n";
    print "Options:\n";
    print "\t--files (-f): Comma separated list of files to examine.\n";
    print "\t--hashfile (-h): Location of stored hashes.\n";
    exit;
}

1;
