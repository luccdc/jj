package LUCCDC::jiujitsu::Util::Linux::Permissions;
use strictures 2;

use File::Grep qw( fgrep );
use Carp;

use Exporter qw(import);
our @EXPORT_OK = qw(get_local_sudo_group require_sudo);

# Naming convention:
# Use get_local for getters that operate on the current machine without parameters.
# Use get_ for those that accept parameters.

sub get_local_sudo_group {
    if ( fgrep { /sudo/ } "/etc/group" ) {
        return "sudo";
    }
    return "wheel";
}

sub require_sudo {
    croak "This command requires sudo." if $<;
}

1;
