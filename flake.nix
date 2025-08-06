{
  description = "Jiu Jitsu: Grapple your Linux Systems.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-25.05";
  };

  outputs = inputs@{ flake-parts, self, ...}:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        # To import a flake module
        # 1. Add foo to inputs
        # 2. Add foo as a parameter to the outputs function
        # 3. Add here: foo.flakeModule
      ];


      # Systems supported
      systems = [ "x86_64-linux" "aarch64-linux" ];

      perSystem = { config, pkgs, lib, system, ... }: {
        _module.args.pkgs = import self.inputs.nixpkgs {
          inherit system;
          config.allowUnfreePredicate = pkg:
            builtins.elem (lib.getName pkg) [
              "vagrant"
            ];
        };

        devShells.default =
          let
            generatedPerlPackages = import ./nix/perl.nix {inherit pkgs lib;};
          in
            pkgs.mkShell {
              name = "jiujitsu";
              buildInputs = with pkgs; [
                vagrant
                perl
                (pkgs.perl540.withPackages (p-pkgs: with p-pkgs; [
                  PLS
                  TryTiny
                  ModulePath
                  CPANPLUS
                  GetoptLongDescriptive
                  LogLog4perl
                  perlcritic
                  strictures
                ]))
              ] ++ generatedPerlPackages;
            };
      };
    };
}
