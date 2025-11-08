package LUCCDC::Jiujitsu::Util::Linux::PerDistro;
use strictures 2;
use Symbol qw( gensym );

use Exporter qw(import);
our @EXPORT_OK = qw(platform);

our $DISTRO_CACHE;

sub _detect_platform {
    if ( -r "/etc/os-release" ) {
        open my $file, '<', "/etc/os-release" or warn "Could not read /etc/os-release: $!";
        if ($file) {
            my %vars;
            while ( my $line = <$file> ) {
                chomp $line;
                if ( my ( $var, $val ) = $line =~ /^([A-Z_]+)=(.+)/ ) {
                    $val =~ s/^"|"$//g;
                    $vars{$var} = $val;
                }
            }
            close $file;

            my $id = $vars{ID} || '';
            my $id_like = $vars{ID_LIKE} || '';

            return 'alpine' if $id eq 'alpine';
            return 'suse'   if $id eq 'sles' || $id eq 'opensuse' || $id_like =~ /suse/;
            return 'rhel'   if $id eq 'rhel' || $id eq 'centos' || $id eq 'fedora' || $id_like =~ /rhel|fedora/;
            return 'debian' if $id eq 'debian' || $id eq 'ubuntu' || $id_like =~ /debian|ubuntu/;
        }
    }

    return 'alpine' if -e '/etc/alpine-release';
    return 'rhel'   if -e '/etc/redhat-release' || -e '/etc/centos-release';
    return 'suse'   if -e '/etc/SuSE-release';
    return 'debian' if -e '/etc/debian_version';

    return 'rhel'   if -x '/usr/bin/rpm' || -x '/bin/rpm';
    return 'debian' if -x '/usr/bin/dpkg' || -x '/bin/dpkg';
    return 'alpine' if -x '/sbin/apk' || -x '/usr/sbin/apk';
    return 'suse'   if -x '/usr/bin/zypper' || -x '/bin/zypper';

    return "debian";
}

sub platform {
    return $DISTRO_CACHE if defined $DISTRO_CACHE;

    $DISTRO_CACHE = _detect_platform();
    return $DISTRO_CACHE;
}

1;
