{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-fesvr";
    src = nixpkgs.fetchgit {
      rev = "0f34d7ad311f78455a674224225f5b3056efba1d";
      url = "git://github.com/riscv/riscv-fesvr.git";
      sha256 = "0xjf0z0ylwwg4kgl05nl3ihpv0frw29ajqlk6clplsby7nfzdcb3";
    };
  }
