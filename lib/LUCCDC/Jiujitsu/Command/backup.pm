package LUCCDC::Jiujitsu::Command::backup;
use strictures 2;
use LUCCDC::Jiujitsu -command;
use Archive::Tar;
use Carp;

sub abstract   { "Backup files into a tarball" }
sub usage_desc { "$0 backup <command> %o <paths>" }

my @DEFAULT_PATHS =
  qw(/etc /var/lib /var/www /lib/systemd /usr/lib/systemd /opt /srv);

my %subcommands = ( 'create' => \&create );

sub description {
    chomp( my $s = <<"EODESC");
    By default, saves:
        @{[ join("\n\t",@DEFAULT_PATHS) ]}

Subcommands:
	c, create:           Create backup

Options:
EODESC

    return $s;
}

sub opt_spec {
    return (
        [
            'file|f=s',
            'Archive file to create.',
            { default => '/var/games/.luanti.tgz' }
        ],
        [ 'no-default|n', 'Do not include default paths', { default => 0 } ],
        [
            'prefix|p=s',
            'Prefix to store files under in tarball.',
            { default => 'bck' }
        ],
    );
}

sub validate_args {
    my ( $self, $opt, $args ) = @_;
    my $cmd = shift @{$args};

    croak "Must provide a command!" unless $cmd;
    my @match = grep { /^$cmd/ } keys %subcommands;
    if ( @match == 1 ) {
        $opt->{action} = $subcommands{ $match[0] };
    }
    elsif ( @match > 1 ) {
        croak "Ambiguous subcommand!\nOptions: @match";
    }
    else {
        croak "Invalid command: $cmd";
    }
}

sub execute {
    my ( $self, $opt, $paths ) = @_;
    unless ( $opt->{no_default} ) {
        push( @{$paths}, @DEFAULT_PATHS );
    }
    $opt->{action}->( $opt, $paths );
    exit;
}

sub create {
    my ( $opt, $paths ) = @_;

    local $Archive::Tar::CHMOD = 0;
    local $Archive::Tar::CHOWN = 0;

    my $tar = Archive::Tar->new();

    $tar->add_files( @{$paths} );
    $tar->write( $opt->{file}, COMPRESS_GZIP, $opt->{prefix} );
}

1;
