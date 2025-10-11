package LUCCDC::jiujitsu::Util::systemd;
use Exporter;

use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
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
