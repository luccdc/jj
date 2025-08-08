package LUCCDC::jiujitsu;

# ABSTRACT: CLI to manage Linux
# VERSION

use strictures 2;

use MooseX::App qw(Color Version Config);

app_namespace 'LUCCDC::jiujitsu::Commands';

option 'global_option' => (
    is            => 'rw',
    isa           => 'Bool',
    documentation => q[Enable this to do fancy stuff],
);    # Global option

has 'private' => ( is => 'rw', );    # not exposed

1;

__END__

=head1 DESCRIPTION
 This command-line interface helps the Liberty CCDC Team to troubleshoot Linux systems.

=head1 USAGE


=head1 AUTHOR
 Judah Sotomayor
