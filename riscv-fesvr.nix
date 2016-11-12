{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-fesvr";
    src = nixpkgs.fetchgit {
      rev = "72f893b927f152d1bab283081f30ebb83ae8534b";
      url = "git://github.com/riscv/riscv-fesvr.git";
      sha256 = "142rp1agbhb6ri845r58207yjx2pd096mwxbr6n70sl4mqvvgvay";
    };
  }
