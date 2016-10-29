{ stdenv, gmp, mpfr, libmpc, wget, curl, texinfo, bison, flex }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-gnu-toolchain";
    buildInputs = [ gmp mpfr libmpc wget curl texinfo bison flex ];
    hardeningDisable = [ "format" ];
    src = nixpkgs.fetchgit {
      rev = "910ea19c5173755f74924d3fc94e168e17693d97";
      url = "git://github.com/riscv/riscv-gnu-toolchain.git";
      sha256 = "16w4nn6gni5n5i2dbb31w4fw2mbahmg4j199drpvpl6mzwydws7j";
    };
  }
