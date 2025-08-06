# How to add a new Perl package to Nix
1. Find the package you want to add on [CPAN](https://metacpan.org/search)
2. Search [nixpkgs](https://search.nixos.org/packages?channel=unstable) for a matching perl540Package to add inside the `perl540.withPackages` expression.
3. No dice? Generate the package with the `./nix/nix-generate-from-cpan.pl` script:
`nix-generate-from-cpan.pl <cpan-pkg-name>`
4. Add the resulting expression into the `let`-expression in `nix/perl.nix`, and add the name to the final list.
