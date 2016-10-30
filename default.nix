{ system ? builtins.currentSystem }:

let
  pkgs =
    (import ./nixpkgs {
      inherit system;
      config = { packageOverrides = pkgs: { glibcCross = toolchain.riscv-glibc; }; };
    }) // { glibcCross = toolchain.riscv-glibc; };
  crossSystem = {
    config = "riscv64-unknown-linux";
    libc = "glibc";
    arch = "riscv";
    platform = rec {
      kernelMajor = "2.6";
      kernelArch = "riscv";
      kernelHeadersBaseConfig = "defconfig"; # TODO: is this right
    };
  };
  stdenv = pkgs.makeStdenvCross pkgs.stdenv crossSystem toolchain.riscv-binutils toolchain.riscv-gcc;
  bits = "64";

  # Components of our cross-compiler toolchain
  toolchain = rec {
    riscv-binutils = import ./riscv-binutils.nix {
      inherit (pkgs) stdenv texinfo flex bison;
      inherit bits;
    };

    linuxHeaders = pkgs.linuxHeaders_4_4;

    riscv-glibc = import ./riscv-glibc.nix {
      inherit (pkgs) stdenv gmp mpfr libmpc;
      inherit bits riscv-gcc-stage1 riscv-binutils linuxHeaders;
      cross = crossSystem;
    };

    riscv-gcc-stage1 = import ./riscv-gcc-stage1.nix {
      inherit (pkgs) stdenv texinfo gmp mpfr libmpc flex bison;
      inherit bits riscv-binutils;
    };

    riscv-gcc = import ./riscv-gcc.nix {
      inherit (pkgs) stdenv texinfo gmp mpfr libmpc flex bison;
      inherit bits riscv-binutils riscv-glibc;
    };
  };
in
  rec {
    llvm-riscv = import ./llvm-riscv.nix {
      version = "3.8";
      inherit (pkgs) perl groff cmake python libffi binutils libxml2 valgrind ncurses zlib compiler-rt_src libcxxabi;
      inherit stdenv;
    };

    riscv-qemu = import ./riscv-qemu.nix {
      inherit (pkgs) autoconf automake libtool flex bison SDL zlib glib pkgconfig python;
      inherit stdenv;
    };

    riscv-fesvr = import ./riscv-fesvr.nix {
      inherit stdenv;
    };

    riscv-pk = import ./riscv-pk.nix {
      inherit stdenv;
    };

    riscv-isa-sim = import ./riscv-isa-sim.nix {
      inherit riscv-fesvr riscv-gnu-toolchain;
      inherit (pkgs) stdenv;
    };

    linux-riscv = import ./linux-riscv.nix {
      inherit (pkgs) perl;
      inherit stdenv;
      riscv-gcc = toolchain.riscv-gcc;
    };

    riscv-busybox = (pkgs.busybox.override { stdenv = stdenv;}).crossDrv;

    riscv-image = import ./riscv-image.nix {
      inherit stdenv bits linux-riscv riscv-busybox;
    };

    # These are broken
    riscv-gnu-toolchain = import ./riscv-gnu-toolchain.nix {
      inherit (pkgs) gmp mpfr libmpc wget curl texinfo bison flex;
      inherit stdenv;
    };

    binutils-riscv = (pkgs.binutils.overrideDerivation (oldAttrs: {
      src = pkgs.fetchgit {
        rev = "67561745546973c1e969348e274129b2d0637b1c";
        url = "git://github.com/riscv/riscv-binutils-gdb.git";
        sha256 = "0fhniqqvh6hn31xnrsdjyikaklp21r718f2kxph4gkx9ma88b9wn";
      };
      dontDisableStatic = true;
    })).override {
      cross = crossSystem;
    };
  }
