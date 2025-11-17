# How to Use
```bash
wget https://github.com/luccdc/jj/releases/latest/download/jj.com
# OR
curl -LO https://github.com/luccdc/jj/releases/latest/download/jj.com
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

# Writing a New Module
Modules are written using [App::Cmd](https://metacpan.org/pod/App::Cmd).
To get started, create a new file under `lib/LUCCDC/Jiujitsu/Command`.
The file must be named after the command you want to create.
For example, the `file` command is placed under `lib/LUCCDC/Jiujitsu/Command/file.pm`.

You must then write a standard header that specifies the package, strictures, and that this is a command module.
Again using `file` as an example:
``` perl
package LUCCDC::Jiujitsu::Command::file;
use strictures 2;
use LUCCDC::Jiujitsu -command;
```
Note that the package must correspond exactly to the name of the file, otherwise `App::Cmd` will be unable to find it.

Once you have your header in place, you must implement a few standard functions.
These are written below with comments.
``` perl
sub abstract {
# Return a one-line string describing the command.
}
sub usage_desc {
# Return the usage string for a module. E.G.:
"$0 file <command> %o <paths>"
}

sub description {
# Return a string that provides a complete description of the module, except for options, which are generated from opt_spec.
}

sub opt_spec {
# Return a list of Getopt::Long::Descriptive-style options.
  return (
    [
      'foo|f=s' => 'Foo to do bar to.',
      {default => 'fizzbuzz'}
    ]
    [
      'verbose|v' => 'Do bar verbosely',
      { default => 0 }
    ]
  );
}

sub validate_args {
my ($self, $opt, $args) = @_;
# OPTIONAL. Perform advanced validation on arguments and options.
# The file command uses this to implement subcommands.
# Called before `execute`
}

sub execute {
my ($self, $opt, $args) = @_;
# Do the main thing this module is for.
}

1; # Be sure your module returns 1!
```

## Implementing Sub-Sub-Commands
If you're writing a module and you want sub-sub commands, there's two ways you could do this.
You can use `$args->[0]` as a subcommand, as [file](./lib/LUCCDC/Jiujitsu/Command/file.pm) does.
This is the best approach for simple use cases.


Or you can create a folder with the name of your subcommand, and inside this folder create more modules that operate as sub-subcommands.
To take the second option, you must add these lines your original command's header:

``` perl
use base qw/App::Cmd::Subdispatch/;
use constant plugin_search_path => __PACKAGE__;
```

and you must remove:

``` perl
use LUCCDC::Jiujitsu -command;
```
Sub-subcommands can be defined exactly the same [as described](#writing-a-new-module).
To select a default sub-subcommand, define `sub default_command` in the subcommand.

``` perl
sub default_command {
  "foo"
}
```


# Related Projects
Check out [jj-rs](https://github.com/luccdc/jj-rs/), our sister project and sometime-competing implementation, written by the legendary Andrew Rioux.
