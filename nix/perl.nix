{pkgs, lib}:
let
      GetoptEuclid =  pkgs.perl540Packages.buildPerlPackage {
        pname = "Getopt-Euclid";
        version = "0.4.8";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/B/BI/BIGPRESH/Getopt-Euclid-0.4.8.tar.gz";
          hash = "sha256-kGcaO7UbsbHLUzdFTWIkyygxlNP+KVSWxraj/8XVaCc=";
        };
        propagatedBuildInputs = [
          (pkgs.perl540.withPackages (p-pkgs: with p-pkgs; [
            PodParser
            IOPager
          ]))
        ];
        meta = {
          homepage = "https://github.com/bigpresh/Getopt-Euclid";
          description = "Executable Uniform Command-Line Interface Descriptions";
          license = with lib.licenses; [ artistic1 gpl1Plus ];
        };
      };

      MooseXApp = pkgs.perl540Packages.buildPerlPackage {
        pname = "MooseX-App";
        version = "1.43";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/M/MA/MAROS/MooseX-App-1.43.tar.gz";
          hash = "sha256-w0YP6wM6R9V7PHbWZUfrf05ncjEnmMfoAp5qq6pnhIc=";
        };
        buildInputs = [
          (pkgs.perl540.withPackages (p-pkgs: with p-pkgs; [
            TestDifferences
            TestException
            TestWarn
            TestDeep
            TestMost TestNoWarnings
          ]))
        ];
        propagatedBuildInputs = [
          (pkgs.perl540.withPackages (p-pkgs: with p-pkgs; [
            IOInteractive
            ConfigAny Moose PodElemental namespaceautoclean
          ]))
        ];
        meta = {
          description = "Write user-friendly command line apps with even less suffering";
          license = with lib.licenses; [ artistic1 gpl1Plus ];
        };
      };

      LinuxSystemd = pkgs.perl540Packages.buildPerlModule {
        pname = "Linux-Systemd";
        version = "1.201600";
        src = pkgs.fetchurl {
          url = "mirror://cpan/authors/id/I/IO/IOANR/Linux-Systemd-1.201600.tar.gz";
          hash = "sha256-8bhLq+80GP2OlE+zc0RPy8h/CAsvzY93O/kYL2bpvYE=";
        };
        nativeBuildInputs = with pkgs; [
          pkg-config
          systemdLibs
        ];
        buildInputs = with pkgs; [
          (perl540.withPackages (p-pkgs: with p-pkgs; [
            ExtUtilsPkgConfig TestCheckDeps TestFatal
          ]))
        ];
        propagatedBuildInputs = with pkgs; [
          (perl540.withPackages (p-pkgs: with p-pkgs; [ Moo strictures ]))
        ];
        meta = {
          homepage = "https://metacpan.org/release/Linux-Systemd";
          description = "Bindings for C<systemd> APIs";
          license = lib.licenses.lgpl21Plus;
        };
      };
in
[
  GetoptEuclid
  MooseXApp
  LinuxSystemd
]
