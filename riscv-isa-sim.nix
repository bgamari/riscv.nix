{ stdenv, riscv-fesvr }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-isa-sim";
    buildInputs = [ riscv-fesvr ];
    src = nixpkgs.fetchgit {
      url = "git://github.com/riscv/riscv-isa-sim.git";
      rev = "40b740c5e0f667088bff442711e350076206be9c";
      sha256 = "032x9whnyy8dbkhzvwj1l2dw1709chvn2j98brk1vafb2qczy7xz";
    };
  }
