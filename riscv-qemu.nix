{ stdenv, autoconf, automake, libtool, flex, bison, SDL, zlib, glib, pkgconfig, python }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    buildInputs = [ autoconf automake libtool flex bison SDL zlib glib pkgconfig python ];
    name = "riscv-qemu";
    hardeningDisable = [ "stackprotector" ];
    enableParallelBuilding = true;
    configureFlags = [
      "--target-list=riscv64-softmmu,riscv32-softmmu,riscv64-linux-user,riscv32-linux-user"
    ];
    src = nixpkgs.fetchgit {
      rev = "05ac735a4b4085e39678c967ecf7f47d45f459e0";
      url = "git://github.com/riscv/riscv-qemu.git";
      sha256 = "06c2sww4nqbxnk6i7ndc2qyykv1r4mcfbnmwi0wv1vklkvpcnb9v";
    };
  }
