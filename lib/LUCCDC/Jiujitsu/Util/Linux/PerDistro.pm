package LUCCDC::Jiujitsu::Util::Linux::PerDistro;
use strictures 2;
use Symbol qw( gensym );

use Exporter qw(import);
our @EXPORT_OK = qw(rhel_or_debian_do rhel_or_debian_return platform);

{
    my %os_release_vars = ();

    sub process_os_release() {

        unless (%os_release_vars) {
            open my $file, '<', "/etc/os-release"
              or die "Can't open /etc/os-release.";

            my @lines = <$file>;

            close($file);

            for my $line (@lines) {
                my ( $varname, $value ) = $line =~ /([^=]+)=(.+)/;
                if ($varname) {
                    $os_release_vars{$varname} = $value;
                }
            }

        }

        return %os_release_vars;
    }
}

sub platform {
    my %vars = process_os_release();
    if ( $vars{"ID"} =~ /debian/ ) {
        return "debian";
    }
    elsif ( $vars{"ID_LIKE"} =~ /rhel/ ) {
        return "rhel";
    }
    else {
        return "debian";
    }
}

sub rhel_or_debian_do {

    my ( $rhel_do, $debian_do, ) = @_;

    if ( platform() == "rhel" ) {
        return $rhel_do->();
    }
    else {
        return $debian_do->();
    }
}

sub rhel_or_debian_return {
    my ( $rhel_return, $debian_return, ) = @_;
    if ( platform() eq "rhel" ) {
        return $rhel_return;
    }
    else {
        return $debian_return;
    }

}

1;
