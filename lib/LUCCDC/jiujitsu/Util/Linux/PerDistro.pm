package LUCCDC::jiujitsu::Util::Linux::PerDistro;
use Symbol qw( gensym );

use Exporter qw(import);
our @EXPORT_OK = qw(&rhel_or_debian_do &platform);

{
    my %os_release_vars = ();

    sub process_os_release() {

        unless (%os_release_vars) {
            my $file = gensym();
            open $file, '<', "/etc/os-release"
              or die "Can't open /etc/os-release.";

            while ( my $line = <$file> ) {
                my ( $varname, $value ) = $line =~ /([^=]+)=(.+)/;
                $os_release_vars{$varname} = $value;
            }
        }

        return %os_release_vars;
    }
}

sub platform {
    my %vars = process_os_release();
    if ( $vars{"ID_LIKE"} =~ /rhel/ ) {
        return "rhel";
    }
    else {
        return "debian";
    }
}

sub rhel_or_debian_do {

    my ( $rhel_do, $debian_do, ) = @_;

    if ( platform() == "rhel" ) {
        return $rhel_do->(@args_list);
    }
    else {
        return $debian_do->(@args_list);
    }
}

1;
