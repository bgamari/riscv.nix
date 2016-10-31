{ bits, withFloat, stdenv, texinfo, flex, bison }:

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
      (if withFloat then "--enable-soft-float" else "--disable-soft-float")
    ];
    src = nixpkgs.fetchgit {
      rev = "2a6d6cca9bb6a900f31f2ba40e48c8e9d239b36d";
      url = "git://github.com/riscv/riscv-binutils-gdb.git";
      sha256 = "0jl36fqzlysapi1d3pm0d6wjpi1sfgq6vbbd7xw5flzh7jzcmlbw";
    };
    enableParallelBuilding = true;
  }
