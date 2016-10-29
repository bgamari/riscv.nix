{ bits, stdenv, riscv-binutils riscv-gcc }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-tests";
    buildInputs = [ riscv-binutils riscv-gcc ];
    src = nixpkgs.fetchgit {
      rev = "f204b5c2b6b8914060614cd77ea10509968c3fa4";
      url = "git://github.com/riscv/riscv-tests.git";
      sha256 = "0fhniqqvh6hn31xnrsdjyikaklp21r718f2kxph4gkx9ma88b9wn";
    };
  }
