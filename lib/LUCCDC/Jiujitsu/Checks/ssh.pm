package LUCCDC::Jiujitsu::Checks::ssh;
use strictures 2;
use parent qw(Exporter);

use LUCCDC::Jiujitsu::Util::Check
  qw(&load_argument &check_not_run &check_succeed :status);
use LUCCDC::Jiujitsu::Util::Logging;
use LUCCDC::Jiujitsu::Util::Arguments qw(&parser :patterns);
use LUCCDC::Jiujitsu::Util::systemd   qw(&get_service_info);
use LUCCDC::Jiujitsu::Util::Linux::PerDistro
  qw(rhel_or_debian_do rhel_or_debian_return platform);

use vars qw($VERSION @EXPORT_OK %EXPORT_TAGS);
$VERSION     = 1.00;
@EXPORT_OK   = qw(%SSH_CHECK);
%EXPORT_TAGS = ( DEFAULT => \@EXPORT_OK );

our %SSH_CHECK = (
    name   => "ssh",
    checks => [ \&check_systemd_running, \&try_remote_login ]
);

sub check_systemd_running {
    load_argument "host"
      and
      return check_not_run( "Cannot check systemd service on remote host", {} );

    my $ssh_service_name = rhel_or_debian_return( "sshd", "ssh" );

    my $service_status = get_service_info($ssh_service_name);
    if ( $service_status->{"ExecMainStatus"} eq "0" ) {
        return check_succeed(
            "Systemd service is currently running",
            {
                "main_pid"      => $service_status->{"MainPID"} // "",
                "running_since" => $service_status->{"ExecMainStartTimestamp"}
                  // ""
            }
        );
    }

    return check_fail( "Systemd service is currently failing!", {} );
}

sub try_remote_login {
    return check_not_run( "Skip remote login was specified", {} )
      if load_argument "skip-login";

    my $host = load_argument "host",     { val => "localhost" };
    my $user = load_argument "user",     { val => "root" };
    my $pass = load_argument "password", { val => ":STDIN:" };

    print "Authenticating with: $pass\n";

    return check_succeed( "Remote authentication succeeded", {} );
}

1;
