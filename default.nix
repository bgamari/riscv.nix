{ system ? builtins.currentSystem }:

let
  pkgs =
    (import ./nixpkgs {
      inherit system;
      config = { packageOverrides = pkgs: { glibcCross = toolchain.riscv-glibc; }; };
    }) // { glibcCross = toolchain.riscv-glibc; };
  crossSystem = {
    config = "riscv64-unknown-linux-gnu";
    libc = "glibc";
    arch = "riscv";
    platform = rec {
      kernelMajor = "2.6";
      kernelArch = "riscv";
      kernelHeadersBaseConfig = "defconfig"; # TODO: is this right
    };
    withTLS = false;
    float = "hard";
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

    gccCrossStageStatic =
      let libcCross1 = null;
      in pkgs.wrapGCCCross {
        gcc = pkgs.forceNativeDrv (overrideGcc (real-gcc.override {
          crossStageStatic = true;
          langCC = false;
          libcCross = libcCross1;
          enableShared = false;
        }));
        libc = libcCross1;
        binutils = riscv-binutils;
        cross = crossSystem;
      };

    real-glibc =
      let drv = pkgs.callPackage ./nixpkgs/pkgs/development/libraries/glibc {
          installLocales = false;
          gccCross = gccCrossStageStatic;
          inherit linuxHeaders;
        };
      in overrideGlibc drv;
    overrideGlibc = drv:
     pkgs.lib.overrideDerivation drv (oldAttrs: {
        src = pkgs.fetchgit {
          rev = "f02ec12b5e5945b9fe6e4f46fe48f13a66dd0b97";
          url = "git://github.com/riscv/riscv-glibc.git";
          sha256 = "16an18mk3hr0qmpv0lqir229d0ikj9m4n6a3q9x9raswn1sf1iyi";
        };
        patches = oldAttrs.patches ++ [
          # Madness pertaining to an interaction between the Linux headers and a
          # FreeBSD compatibility hack in glibc.
          ./workaround-ptrace_getregs.patch
        ];
     });
    riscv-glibc = pkgs.forceNativeDrv real-glibc;

    riscv-gcc = pkgs.wrapGCCCross {
      gcc = pkgs.forceNativeDrv (overrideGcc real-gcc);
      libc = riscv-glibc;
      binutils = riscv-binutils;
      cross = crossSystem;
    };
    real-gcc =
      pkgs.callPackage ./nixpkgs/pkgs/development/compilers/gcc/6 {
        cross = crossSystem;
        binutilsCross = riscv-binutils;
        libcCross = riscv-glibc;
        noSysDirs = true;
      };

    # Setup source for GCC
    overrideGcc = drv:
     pkgs.lib.overrideDerivation drv (oldAttrs: {
        src = pkgs.fetchgit {
          rev = "9b2f75b37e2626e78226479e7fdceda06357bfa8";
          url = "git://github.com/riscv/riscv-gcc.git";
          sha256 = "0n6lf1zm82lwyv7igfkmhh8kscg3lr95xa3lzwwqa7arddv9m7iz";
        };

        # we need flex since it's a development snapshot
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.flex pkgs.bison ];
      });
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
      inherit riscv-fesvr;
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

    inherit toolchain;
  }
