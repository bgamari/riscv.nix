{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-pk";
    src = nixpkgs.fetchgit {
      rev = "7a7106885367201ffbfd6f5568d8c5262dbb766d";
      url = "git://github.com/riscv/riscv-pk.git";
      sha256 = "14n7dzcihihpllamkcn8ya8zkvfpspp1qakysdbvjc6hn4nypg9z";
    };
  }
