package LUCCDC::jiujitsu::Util::Arguments;
use LUCCDC::jiujitsu::Commands::ssh;

# TODO Enable during testing VVV
use strictures;

sub parser {

    # Initialize hash for arguments
    my ( $options_ref, $subcommand_ref, $meta_option_ref ) = @_;
    my @options     = @{$options_ref};
    my %meta_option = %{$meta_option_ref};
    my %subcommand  = %{$subcommand_ref};

    my %arg = map { $_->{flag} => $_->{val} } @options;

    # Master regex for meta and subcommands
    my $meta_option_or_subcommand = join '|', reverse sort keys %meta_option,
      reverse sort keys %subcommand;

    my $parse = sub {
        my ($cmdline) = @_;
        pos $cmdline = 0;

      ARG:
        while ( pos $cmdline < length $cmdline ) {

            # Attempt to match a meta option or subcommand.
            if ( my ($meta) =
                $cmdline =~ m/^ \s* ($meta_option_or_subcommand) \b /gcxms )
            {
                if ( my $m = $meta_option{$meta} ) {
                    $m->();
                }
                else {

  # If we've matched a command, we do not need to continue processing arguments.
  # Pass the rest of the line to the subcommand and stop.
                    $subcommand{$meta}->( substr( $cmdline, pos($cmdline) ) );
                    exit;
                }
                next ARG;
            }

            # Attempt to match an option
            for my $opt_ref (@options) {
                if ( my ($val) =
                    $cmdline =~
                    m/\G \s* $opt_ref->{flag} $opt_ref->{pat} /gcxms )
                {
                    # And, if so, storing the value and moving on...
                    $arg{ $opt_ref->{flag} } = $val;
                    next ARG;
                }
            }

            # Report unknown flags.
            my ($unknown) = $cmdline =~ m/ (\S*) /xms;
            die "Unknown cmdline flag: $unknown";
        }

        print $arg{'-in'};
    };
    return $parse;
}

1;
