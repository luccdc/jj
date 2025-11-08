package LUCCDC::Jiujitsu::Util::Service;
use strictures 2;
use parent qw(Exporter);

use LUCCDC::Jiujitsu::Util::Linux::PerDistro qw(platform);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(check_service);
%EXPORT_TAGS = (
    DEFAULT => [qw(&check_service)],

    #Both    => [qw(&func1 &func2)]
);

sub check_service {
    my ($service) = @_;

    my $status;
    my $status_regex;
    if (platform() eq 'alpine') {
	    $status = "rc-service $service status 2>/dev/null";
	    $status_regex = qr/status: \s+ started/;
    }
    else {
	    $status = `systemctl is-active $service 2>/dev/null`;
	    $status_regex = qr/^active/;
    }

    if ( $status =~ $status_regex ) {
        return 1;
    }
    else {
        return 0;
    }
}

1;
