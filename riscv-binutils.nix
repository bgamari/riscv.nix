{ bits, stdenv, texinfo, flex, bison }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-binutils";
    buildInputs = [ texinfo flex bison ];
    # Since we statically build readline
    dontDisableStatic = true;
    configureFlags = [
      "--target=riscv${bits}-unknown-linux-gnu"
      "--disable-nls"
      "--disable-werror"
      "--disable-multilib"
    ];
    src = nixpkgs.fetchgit {
      rev = "67561745546973c1e969348e274129b2d0637b1c";
      url = "git://github.com/riscv/riscv-binutils-gdb.git";
      sha256 = "0fhniqqvh6hn31xnrsdjyikaklp21r718f2kxph4gkx9ma88b9wn";
    };
    enableParallelBuilding = true;
  }
