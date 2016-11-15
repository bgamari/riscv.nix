{ system ? builtins.currentSystem }:

let
  # Use software floating-point in glibc
  #
  # withFloat=false:
  #     binutils: --disable-soft-float
  #     glibc:    (none)
  #     gcc:      --disable-soft-float
  #
  # withFloat=true
  #     binutils: --enable-soft-float
  #     glibc:    --without-fp
  #     gcc:      --enable-soft-float --with-float=soft
  withFloat = true;

  # with atomics
  withAtomic = true;
in
let
  pkgs =
    (import ./nixpkgs {
      inherit system;
      config = { packageOverrides = pkgs: { glibcCross = toolchain.riscv-glibc; }; };
    }) // { glibcCross = toolchain.riscv-glibc; crossSystem = crossSystem; };

  extraGccConfigureFlags =
    if withFloat then "--enable-soft-float" else "--disable-soft-float";

  crossSystem = {
    config = "riscv64-unknown-linux-gnu";
    libc = "glibc";
    arch = "riscv";
    platform = {
      kernelMajor = "2.6";
      kernelArch = "riscv";
      kernelHeadersBaseConfig = "defconfig"; # TODO: is this right
    };
    gcc = {
      arch = "RV64IMAFD";
      float = if withFloat then "soft" else "hard";
    };
    withTLS = false;
    float = if withFloat then "soft" else "hard";
  };
  stdenv = pkgs.makeStdenvCross pkgs.stdenv crossSystem toolchain.riscv-binutils toolchain.riscv-gcc;
  bits = "64";

  # Components of our cross-compiler toolchain
  toolchain = rec {
    riscv-binutils = import ./riscv-binutils.nix {
      inherit (pkgs) texinfo flex bison;
      inherit bits stdenv withFloat;
    };

    linuxHeaders = pkgs.linuxHeaders_4_4;

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

    riscv-gcc = pkgs.wrapGCCCross {
      gcc = pkgs.forceNativeDrv (overrideGcc real-gcc);
      libc = riscv-glibc;
      binutils = riscv-binutils;
      cross = crossSystem;
    };
    real-gcc =
      pkgs.callPackage ./nixpkgs/pkgs/development/compilers/gcc/6 {
        inherit stdenv;
        cross = crossSystem;
        binutilsCross = riscv-binutils;
        libcCross = riscv-glibc;
        noSysDirs = true;
      };

    # Setup source for GCC
    overrideGcc = drv:
     pkgs.lib.overrideDerivation drv (oldAttrs: {
        src = pkgs.fetchgit {
          rev = "879263a2c8384f9c9e679505186148fc41e40f84";
          url = "git://github.com/riscv/riscv-gcc.git";
          sha256 = "01g1idc9ksp50g215nw956y26byl2gxkz3ww5nawn480rays2ywk";
        };

        # we need flex since it's a development snapshot
        nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.flex pkgs.bison ];
        # For withFloat
        configureFlags = oldAttrs.configureFlags + extraGccConfigureFlags;
      });

    riscv-gdb = pkgs.lib.overrideDerivation pkgs.gdb (oldAttrs: {
      nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.flex pkgs.yacc ];
      src = pkgs.fetchgit {
        rev = "2a6d6cca9bb6a900f31f2ba40e48c8e9d239b36d";
        url = "git://github.com/riscv/riscv-binutils-gdb.git";
        sha256 = "0jl36fqzlysapi1d3pm0d6wjpi1sfgq6vbbd7xw5flzh7jzcmlbw";
        name = "binutils";
      };
      sourceRoot = "binutils/gdb";
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

    riscv-pk = (import ./riscv-pk.nix {
      inherit stdenv;
    }).crossDrv;

    riscv-isa-sim = import ./riscv-isa-sim.nix {
      inherit riscv-fesvr;
      inherit (pkgs) stdenv;
    };

    linux-riscv = import ./linux-riscv.nix {
      inherit (pkgs) perl;
      inherit stdenv;
      riscv-gcc = toolchain.riscv-gcc;
    };

    riscv-libffi = (import ./libffi.nix {
      inherit stdenv;
      inherit (pkgs) fetchgit dejagnu autoconf automake libtool texinfo;
    }).crossDrv;

    riscv-busybox = (pkgs.busybox.override { stdenv = stdenv;}).crossDrv;

    #riscv-image = import ./riscv-image.nix {
    #  inherit stdenv bits linux-riscv riscv-busybox;
    #};

    inherit toolchain stdenv;
  }
