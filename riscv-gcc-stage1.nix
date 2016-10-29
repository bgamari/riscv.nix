{ bits, stdenv, texinfo, gmp, mpfr, libmpc, flex, bison, riscv-binutils }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-gcc-stage1";
    buildInputs = [ texinfo gmp mpfr libmpc flex bison riscv-binutils ];
    configureFlags = [
      "--target=riscv${bits}-unknown-linux-gnu"
      "--with-newlib"
      "--without-headers"
      "--disable-shared"
      "--disable-threads"
      "--enable-tls"
      "--enable-languages=c,c++"
      "--disable-libatomic"
      "--disable-libmudflap"
      "--disable-libssp"
      "--disable-libquadmath"
      "--disable-libgomp"
      "--disable-nls"
      "--disable-bootstrap"
      "--disable-werror"
      "--disable-multilib"
      "--with-arch=RV64IMAFD"
    ];
    hardeningDisable = [ "format" ];
    dontDisableStatic = true;
    enableParallelBuilding = true;
    src = nixpkgs.fetchgit {
      rev = "9b2f75b37e2626e78226479e7fdceda06357bfa8";
      url = "git://github.com/riscv/riscv-gcc.git";
      sha256 = "0n6lf1zm82lwyv7igfkmhh8kscg3lr95xa3lzwwqa7arddv9m7iz";
    };

    # Perform the build in a different directory.
    configurePhase = ''
      mkdir build
      cd build
      ../configure ${builtins.concatStringsSep " " configureFlags}
    '';

    buildPhase = ''
      make inhibit-libc=true all-gcc
      make inhibit-libc=true all-libcc1
      make inhibit-libc=true install-gcc
      make inhibit-libc=true all-target-libgcc
      make inhibit-libc=true install-target-libgcc
    '';
    installPhase = "";
    dontStrip = true;
    NIX_STRIP_DEBUG = 0;
  }
