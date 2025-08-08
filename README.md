# How to run while testing
Assuming you have all the perl dependencies installed, use:
`perl -I ./lib/ bin/jiujitsu` from the repository root.

# Where to get dependencies from
Q: I need a library that does foo, don't want to write it myself. Where can I find it?

A: CPAN! Check this list of high-quality tools:
- https://metacpan.org/pod/Task::Kensho
Or search for it:
- https://metacpan.org

# How to add a new Perl package to Nix
1. Find the package you want to add on [CPAN](https://metacpan.org/search)
2. Search [nixpkgs](https://search.nixos.org/packages?channel=unstable) for a matching perl540Package to add inside the `perl540.withPackages` expression.
3. No dice? Generate the package with the `./nix/nix-generate-from-cpan.pl` script:
`nix-generate-from-cpan.pl <cpan-pkg-name>`
4. Add the resulting expression into the `let`-expression in `nix/perl.nix`, and add the name to the final list.

# How to define a new command
1. Is it a top-level command? 
    - Yes? These go in ./lib/LUCCDC/jiujitsu/Commands.
    - No? Put it in the appropriate subfolder. For example, `ssh service` lives in ./lib/LUCCDC/jiujitsu/Commands/ssh/.
2. Use the standard boilerplate for a command:

```perl
package LUCCDC::jiujitsu::Commands::<your-command>;
use MooseX::App::Command;

use strictures 2;

extends qw(LUCCDC::jiujitsu);    # Include global options
# Default method, called by the containing app when the subcommand is used.
sub run {
    my ($self)    = @_;
    # Do something
}
1; # Modules must return true, Perl makes the rules.
```
3. Add options or parameters 
Options are passed with flags, such as `-e` or `--help`.

``` perl
option 'xyz' => (
    is => 'rw',
    isa => 'Str',
);
# Usage in the commandline: myapp --xyz <some-string>
```

Parameters are positional and not flags.

```perl
parameter 'name' => (
    is            => 'rw',
    isa           => 'Str',
);
# Usage in the command line: myapp <name>
```

Both options and parameters can be accessed via the `$self` object in `run` (from the boilerplate above).
This object is a 
[reference](https://perldoc.perl.org/perlref) 
to a 
[hash](https://www.perl.com/article/27/2013/6/16/Perl-hash-basics-create-update-loop-delete-and-sort/).

You can access a given parameter or option with its name, for example:

``` perl
my $name = $self->{'name'};
```


# Packaging Options
- https://metacpan.org/pod/App::FatPacker
- https://metacpan.org/pod/pp
