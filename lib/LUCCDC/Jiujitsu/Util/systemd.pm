package LUCCDC::Jiujitsu::Util::systemd;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(check_service);
%EXPORT_TAGS = (
    DEFAULT => [qw(&check_service)],

    #Both    => [qw(&func1 &func2)]
);

sub check_service {
    my ($service) = @_;

    my $status = `systemctl is-active $service 2>/dev/null`;

    if ( $status =~ /^active/ ) {
        return 1;
    }
    else {
        return 0;
    }

}

1;
