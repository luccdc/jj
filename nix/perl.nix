{pkgs, lib}:
let
  inherit (pkgs) fetchurl perl540Packages;
  inherit (perl540Packages) buildPerlPackage buildPerlModule;
  inherit (pkgs.perl540) withPackages;

  GetoptEuclid =  buildPerlPackage {
    pname = "Getopt-Euclid";
    version = "0.4.8";
    src = fetchurl {
      url = "mirror://cpan/authors/id/B/BI/BIGPRESH/Getopt-Euclid-0.4.8.tar.gz";
      hash = "sha256-kGcaO7UbsbHLUzdFTWIkyygxlNP+KVSWxraj/8XVaCc=";
    };
    propagatedBuildInputs = [
      (withPackages (p-pkgs: with p-pkgs; [
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

  LinuxSystemd = buildPerlModule {
    pname = "Linux-Systemd";
    version = "1.201600";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IO/IOANR/Linux-Systemd-1.201600.tar.gz";
      hash = "sha256-8bhLq+80GP2OlE+zc0RPy8h/CAsvzY93O/kYL2bpvYE=";
    };
    nativeBuildInputs = with pkgs; [
      pkg-config
      systemdLibs
    ];
    buildInputs = with pkgs; [
      (withPackages (p-pkgs: with p-pkgs; [
        ExtUtilsPkgConfig TestCheckDeps TestFatal
      ]))
    ];
    propagatedBuildInputs = with pkgs; [
      (withPackages (p-pkgs: with p-pkgs; [ Moo strictures ]))
    ];
    meta = {
      homepage = "https://metacpan.org/release/Linux-Systemd";
      description = "Bindings for C<systemd> APIs";
      license = lib.licenses.lgpl21Plus;
    };
  };

  indirect = buildPerlPackage {
    pname = "indirect";
    version = "0.39";
    src = fetchurl {
      url = "mirror://cpan/authors/id/V/VP/VPIT/indirect-0.39.tar.gz";
      hash = "sha256-cXM8TDSOmP3VdbRKUgQkKMOYiKGMJWVu/lnvPX0NJ+U=";
    };
    meta = {
      homepage = "http://search.cpan.org/dist/indirect/";
      description = "Lexically warn about using the indirect method call syntax";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  multidimensional = buildPerlPackage {
    pname = "multidimensional";
    version = "0.014";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IL/ILMARI/multidimensional-0.014.tar.gz";
      hash = "sha256-EusUMXRHvRWrl5lnfbntog54TYsRPkSl9vEfUp6GLF8=";
    };
    buildInputs = [ perl540Packages.ExtUtilsDepends ];
    propagatedBuildInputs = [ perl540Packages.BHooksOPCheck ];
    meta = {
      homepage = "https://github.com/ilmari/multidimensional";
      description = "Disables multidimensional array emulation";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  barewordfilehandles = buildPerlPackage {
    pname = "bareword-filehandles";
    version = "0.007";
    src = fetchurl {
      url = "mirror://cpan/authors/id/I/IL/ILMARI/bareword-filehandles-0.007.tar.gz";
      hash = "sha256-QTRTNxbYevj/9W4lDEiK0G3wp7/0jnz33mP/a8jZwX8=";
    };
    buildInputs = [ perl540Packages.ExtUtilsDepends ];
    propagatedBuildInputs = [ perl540Packages.BHooksOPCheck ];
    meta = {
      homepage = "https://github.com/ilmari/bareword-filehandles";
      description = "Disables bareword filehandles";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  NetDBus = buildPerlPackage {
    pname = "Net-DBus";
    version = "1.2.0";
    src = fetchurl {
      url = "mirror://cpan/authors/id/D/DA/DANBERR/Net-DBus-1.2.0.tar.gz";
      hash = "sha256-56GsnvShI1s/29WIj4bDRxgjBkZ715q8mwdWpktEHLw=";
    };
    buildInputs = with perl540Packages; [ TestPod TestPodCoverage ];
    nativeBuildInputs = with pkgs; [
      pkg-config
      dbus
    ];
    propagatedBuildInputs = [ perl540Packages.XMLTwig ];
    meta = {
      homepage = "http://www.freedesktop.org/wiki/Software/dbus";
      description = "Extension for the DBus bindings";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };

  PerlDistAPPerl = buildPerlPackage {
    pname = "Perl-Dist-APPerl";
    version = "0.6.1";
    src = fetchurl {
      url = "mirror://cpan/authors/id/G/GA/GAHAYES/Perl-Dist-APPerl-v0.6.1.tar.gz";
      hash = "sha256-H455GwzKbVHpIJ2THq50rIBLPidkVrYMfYDRtZ0687M=";
    };
    buildInputs = [ perl540Packages.FileShareDirInstall ];
    propagatedBuildInputs = [ pkgs.cosmocc pkgs.wget pkgs.zip perl540Packages.FileShareDir ];
    meta = {
      homepage = "https://computoid.com/APPerl";
      description = "Actually Portable Perl";
      license = with lib.licenses; [ artistic1 gpl1Plus ];
    };
  };


in
{
  inherit
    GetoptEuclid
    LinuxSystemd
    indirect
    multidimensional
    barewordfilehandles
    NetDBus
    PerlDistAPPerl;
}
