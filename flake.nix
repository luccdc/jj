{
  description = "Jiu Jitsu: Grapple your Linux Systems.";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:nixos/nixpkgs?ref=nixos-unstable";

    cosmo = {
      url = "https://cosmo.zip/pub/cosmocc/cosmocc-3.3.10.zip";
      flake = false;
    };

    perlSrc = {
      url = "file+https://github.com/Perl/perl5/archive/refs/tags/v5.36.3.tar.gz";
      flake = false;
    };
  };

  outputs = inputs@{ flake-parts, self, perlSrc, cosmo, ...}:
    flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [];

      systems = [ "x86_64-linux" ];

      perSystem = { config, pkgs, lib, system, ... }:
        let
          generatedPerlPackages = import ./nix/perl.nix {inherit pkgs lib;};

          #
          # NOTE: ADD NEW PERL PACKAGES HERE
          #
          # In nixpkgs? Just the name: `ModulePath`
          # Generated from CPAN? Use `generatedPerlPackages.ModulePath`
          # Obviously replace `ModulePath` with the name of your package.
          perlDeps = with  pkgs.perl540Packages; [
            ModulePath
            FileGrep
            strictures
            AppCmd
          ];

          apperl-link = pkgs.writeShellScriptBin "apperl-link" ''
rm -fr ./.apperl/nix-links && echo "Removing previous links directory..."
mkdir -p ./.apperl/nix-links && echo "Creating links directory..."
echo -e "Creating links to CPAN sources...\ninstall_modules entries:"
${lib.concatMapStringsSep "\n" (p: ''ln -s ${toString p.out.src} ./.apperl/nix-links/${p.pname}-${p.version}.tar.gz
                                     echo -e '\t".apperl/nix-links/${p.pname}-${p.version}.tar.gz"','')  perlDeps}
'';

          jiujitsu = let
            perlUrl = "file+https://github.com/Perl/perl5/archive/refs/tags/v5.36.3.tar.gz";
            apperl-project = lib.recursiveUpdate (lib.importJSON ./apperl-project.json) {
              apperl_configs.jiujitsu = {
                perl_url = perlUrl;
              };
            };

            apperl-site.cosmocc = "${cosmo}";
          in
            pkgs.stdenv.mkDerivation rec {
              pname = "jiujitsu";
              src = ./.;
              version = "0.1.0";

              buildInputs = [
                apperl-link
                pkgs.perl
                generatedPerlPackages.PerlDistAPPerl
              ];
              nativeBuildInputs = perlDeps;

              outputs = ["out"];

              HOME = "./fake-home";

              dontFixup = true;

              preConfigure = ''
                mkdir -p $HOME/.config/apperl/ .apperl/o
                cp ${(pkgs.writers.writeJSON "apperl-project.json" apperl-project)} ./apperl-project.json
                cp ${(pkgs.writers.writeJSON "site.json" apperl-site)} $HOME/.config/apperl/site.json
                cp ${perlSrc} .apperl/o/${baseNameOf apperl-project.apperl_configs.jiujitsu.perl_url}
                apperl-link
              '';

              configurePhase = ''
                runHook preConfigure
                apperlm configure
              '';

              buildPhase = ''
                apperlm build
              '';

              installPhase = ''
                mkdir -p $out/bin
                cp ./${apperl-project.apperl_configs.jiujitsu.dest} $out/bin
                cp ./${apperl-project.apperl_configs.jiujitsu.dest}.dbg $out/bin
              '';
            };

        in
          {
            _module.args.pkgs = import self.inputs.nixpkgs {
              inherit system;
              config.allowUnfreePredicate = pkg:
                builtins.elem (lib.getName pkg) [
                  "vagrant"
                ];
            };

            packages = {
              inherit jiujitsu;
            };

            devShells.default = pkgs.mkShell {
              name = "jiujitsu";
              buildInputs = with pkgs; [
                vagrant

                # CLI Tools
                perl
                perl540Packages.PerlCritic
                perl540Packages.PLS
                generatedPerlPackages.PerlDistAPPerl
                apperl-link

                # Needed for the CPAN generator script
                (perl540.withPackages(p-pkgs: with p-pkgs; [
                  AppFatPacker
                  GetoptLongDescriptive
                  LogLog4perl
                  Readonly
                  CPANPLUS
                ]))

              ] ++ perlDeps;

              # Local dev demands we extend PERL5LIB to include our local library.
              # apperl-link ensures we can also run local builds.
              shellHook = ''
                export PERL5LIB="$(pwd)/lib/:$PERL5LIB"
                  apperl-link
'';
            };
          };
    };
}
