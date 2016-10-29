{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-pk";
    src = nixpkgs.fetchgit {
      rev = "85ae17aa149b9ea114bdd70cc30ea7e73813fb48";
      url = "git://github.com:riscv/riscv-pk.git";
      sha256 = "0jlj0vhmxxl2w9xjzhdcl4k1p3dgq93npqpqkjg7qcngpjlmifd2";
    };
  }
