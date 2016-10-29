{ system ? builtins.currentSystem }:

let
  pkgs = import <nixpkgs> { inherit system; };
  bits = "64";
in
  rec {
    llvm-riscv = import ./llvm-riscv.nix {
      version = "3.8";
      inherit (pkgs) stdenv perl groff cmake python libffi binutils libxml2 valgrind ncurses zlib compiler-rt_src libcxxabi;
    };

    riscv-qemu = import ./riscv-qemu.nix {
      inherit (pkgs) stdenv autoconf automake libtool flex bison SDL zlib glib pkgconfig python;
    };

    riscv-fesvr = import ./riscv-fesvr.nix {
      inherit (pkgs) stdenv;
    };

    riscv-binutils = import ./riscv-binutils.nix {
      inherit (pkgs) stdenv texinfo flex bison;
      inherit bits;
    };

    riscv-glibc = import ./riscv-glibc.nix {
      inherit (pkgs) stdenv gmp mpfr libmpc;
      inherit bits riscv-gcc-stage1;
    };

    riscv-gcc-stage1 = import ./riscv-gcc-stage1.nix {
      inherit (pkgs) stdenv texinfo gmp mpfr libmpc flex bison;
      inherit bits riscv-binutils;
    };

    riscv-gcc = import ./riscv-gcc.nix {
      inherit (pkgs) stdenv texinfo gmp mpfr libmpc flex bison;
      inherit bits riscv-binutils;
      glibCross = riscv-glibc;
    };

    riscv-pk = import ./riscv-pk.nix {
      inherit (pkgs) stdenv;
    };

    riscv-isa-sim = import ./riscv-isa-sim.nix {
      inherit riscv-fesvr riscv-gnu-toolchain;
      inherit (pkgs) stdenv;
    };

    linux-riscv = import ./linux-riscv.nix {
      inherit (pkgs) stdenv;
    };

    # These are broken
    riscv-gnu-toolchain = import ./riscv-gnu-toolchain.nix {
      inherit (pkgs) stdenv gmp mpfr libmpc wget curl texinfo bison flex;
    };

    binutils-riscv = (pkgs.binutils.overrideDerivation (oldAttrs: {
      src = pkgs.fetchgit {
        rev = "67561745546973c1e969348e274129b2d0637b1c";
        url = "git://github.com/riscv/riscv-binutils-gdb.git";
        sha256 = "0fhniqqvh6hn31xnrsdjyikaklp21r718f2kxph4gkx9ma88b9wn";
      };
      dontDisableStatic = true;
    })).override {
      cross = {
        config = "riscv64-unknown-linux";
      };
    };
  }
