package LUCCDC::Jiujitsu;
use App::Cmd::Setup -app;
use strictures 2;

sub _module_pluggable_options {
    return ( max_depth => 4 );

    # Don't search for commands below four levels.
    # 1       2         3        4
    # LUCCDC::Jiujitsu::Command::Foo
}

1;
