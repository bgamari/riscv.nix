{ stdenv, riscv-gnu-toolchain, riscv-fesvr }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-isa-sim";
    buildInputs = [ riscv-fesvr riscv-gnu-toolchain ];
    src = nixpkgs.fetchgit {
      rev = "3bfc00ef2a1b1f0b0472a39a866261b00f67027e";
      url = "git://github.com/riscv/riscv-isa-sim.git";
      sha256 = "0psikrlhxayrz7pimn9gvkqd5syvcm3l90hnwkgbd63nmv11fazi";
    };
  }
