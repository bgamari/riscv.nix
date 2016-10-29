{ system ? builtins.currentSystem }:

let
  pkgs = import <nixpkgs> { inherit system; };
in
  rec {
    llvm-riscv = import ./llvm-riscv.nix {
      version = "3.8";
      inherit (pkgs) stdenv perl groff cmake python libffi binutils libxml2 valgrind ncurses zlib compiler-rt_src libcxxabi;
    };

    riscv-fesvr = import ./riscv-fesvr.nix {
      inherit (pkgs) stdenv;
    };

    riscv-gnu-toolchain = import ./riscv-gnu-toolchain.nix {
      inherit (pkgs) stdenv;
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
  }
