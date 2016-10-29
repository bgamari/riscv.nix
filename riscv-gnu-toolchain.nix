{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-gnu-toolchain";
    src = nixpkgs.fetchgit {
      rev = "728afcddcb0526a0f6560c4032da82805f054d58";
      url = "git://github.com/riscv/riscv-gnu-toolchain.git";
      sha256 = "0n09ypk5drsrl0g59yw71py817kcmbs60jbkcsxbz8lhsaklr39g";
    };
  }
