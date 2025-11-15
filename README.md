# How to Use
```bash
wget https://github.com/luccdc/jj/releases/latest/download/jj.tgz
# OR
curl -LO https://github.com/luccdc/jj/releases/latest/download/jj.tgz
```

```bash
jj.com # Runs jiujitsu

# Run as perl
cp jj.com perl
./perl

# Run as perldoc
cp jj.com perldoc
./perldoc
```

# How to Develop
You'll need to have Nix installed to work on this.
If you're on Windows, either WSL or a virtual machine work perfectly.
Once you've got Linux, please:
1. [Install nix](https://nixos.org/download/)
2. Enable flakes by adding this line in `~/.config/nix/nix.conf`:
    `experimental-features = nix-command flakes`
3. Reload the nix daemon with `systemctl`.

Next, clone this repository:
(Make sure you're in an appropriate directory!)
``` shell
git clone git@github.com:luccdc/jj.git
cd jj
```
From inside the repo, running `nix develop` should bring you into the nix development environment.
The first time you do this it may take a few minutes to load, that is normal.

You can run intermediate work using `./bin/jj` from the repository root.

## Producing Builds
While developing, you can run the builder with `apperlm configure && apperlm build`.
Note that these builds are _not_ produced cleanly. They will install cosmocc and perl separately the first time you run them.
In order to produce a release build, run `nix build .#jiujitsu`. In 45 minutes or so, **boom!** `jj.com` will appear in `result/bin/`.

## Where to get dependencies from

Q: I need a library that does foo, don't want to write it myself. Where can I find it?

A: CPAN! Check this list of high-quality tools:
- https://metacpan.org/pod/Task::Kensho
Or search for it:
- https://metacpan.org

Once you have a good dependency in mind, [add it to nix](#how-to-add-a-new-perl-package-to-nix).

## How to add a new Perl package to Nix
1. Find the package you want to add on [CPAN](https://metacpan.org/search)
2. Search [nixpkgs](https://search.nixos.org/packages?channel=unstable) for a matching perl540Package.
3. No dice? Generate the package with the `./nix/nix-generate-from-cpan.pl` script:
`nix-generate-from-cpan.pl <cpan-pkg-name>`
  - Add the resulting expression into the `let`-expression in `nix/perl.nix`, and add the name to the final object.
4. Add your package to the perlDeps list.
   If you got it from nixpkgs, just the name please.
   If you generated it, prefix the name with `generatedPerlPackages`.

# Argument Parsing
**NOTICE: This crappy argparser will shortly be replaced with something better.**

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

# Related Projects
Check out [jj-rs](https://github.com/luccdc/jj-rs/), our sister project and sometime-competing implementation, written by the legendary Andrew Rioux.
