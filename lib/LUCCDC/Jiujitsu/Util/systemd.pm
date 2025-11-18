package LUCCDC::Jiujitsu::Util::systemd;
use strictures 2;
use parent qw(Exporter);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(check_service get_service_info);
%EXPORT_TAGS = (
    DEFAULT => [qw(&check_service get_service_info)],

    #Both    => [qw(&func1 &func2)]
);

sub check_service {
    my ($service) = @_;

    my $svc_info = get_service_info($service);
    my %svc_map  = %{$svc_info};

    return $svc_map{"ActiveState"} eq "active";
}

sub get_service_info {
    my ($service) = @_;

    my %status_results;

    open my $status_cmd, '-|', "systemctl show --no-pager $service";
    while (<$status_cmd>) {
        /^([^=]*)=(.+)/;
        $status_results{$1} = $2;
    }
    close $status_cmd;

    return \%status_results;
}

1;
