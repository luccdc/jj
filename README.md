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

# Argument Parsing
Argument parsing uses the [Arguments](./lib/LUCCDC/jiujitsu/Util/Arguments.pm) module.
A parser is a closure that can be called on a string representing the command-line.
Each parser takes two arguments:
- `options`: A list of hashes, each with four key-value pairs:
  - `name`: The name of the option, to be used when accessing it in the arguments table.
  - `flag`: The pattern that matches the flag for the option. Something like `--port|-p` would provide both a short and long flag.
  - `val`: The default value for the option. Mandatory for now, will be optional later.
  - `pat`: The pattern to match the value provided with the flag. 
- `subcommands`: A hash whose keys are the command and whose values are the function to call. If you want a short option for a subcommand, add another entry to the hash.
``` perl
my @options = (
    {
        name => 'port',
        flag => '--port|-p',
        val  => 22,
        pat  => number_pat,
    }
);

my %subcommands = (
    'check'  => \&check,
    '--help' => sub { print "ssh help"; exit; }
);
my $toplevel_parser = parser( \@options, \%subcommands );
my %arg = $toplevel_parser->($cmdline);
```
The above exemplifies the creation and use of a parser.
A parser closure will return a hash of the arguments, keyed to the names of options.
If it encounters a subcommand, it will run that command and exit instead of returning.

# Packaging Options
- https://metacpan.org/pod/App::FatPacker
- https://metacpan.org/pod/pp
