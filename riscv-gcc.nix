{ bits, stdenv, texinfo, gmp, mpfr, libmpc, flex, bison, riscv-binutils, glibCross }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-gcc";
    buildInputs = [ texinfo gmp mpfr libmpc flex bison riscv-binutils glibCross ];
    configureFlags = [
      "--target=riscv${bits}-unknown-linux-gnu"
      "--with-newlib"
      "--enable-shared"
      "--enable-tls"
      "--enable-languages=c,c++,fortran"
      "--disable-libmudflap"
      "--disable-libssp"
      "--disable-libquadmath"
      "--disable-nls"
      "--disable-bootstrap"
      "--disable-werror"
      "--with-arch=RV64IMAFD"
      "--disable-multilib"
    ];
    hardeningDisable = [ "format" ];
    dontDisableStatic = true;
    enableParallelBuilding = true;
    dontStrip = true;
    NIX_STRIP_DEBUG = 0;
    src = nixpkgs.fetchgit {
      rev = "9b2f75b37e2626e78226479e7fdceda06357bfa8";
      url = "git://github.com/riscv/riscv-gcc.git";
      sha256 = "0n6lf1zm82lwyv7igfkmhh8kscg3lr95xa3lzwwqa7arddv9m7iz";
    };

    # Perform the build in a different directory.
    configurePhase = ''
      mkdir build
      cd build
      ../configure --prefix=$prefix ${builtins.concatStringsSep " " configureFlags}
    '';
  }
