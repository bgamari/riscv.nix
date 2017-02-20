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
    (import ./nixpkgs ({
      inherit crossSystem system;
      config = { inherit packageOverrides; };
    }));


  overrideGlibc = pkgs: drv:
    pkgs.lib.overrideDerivation drv (oldAttrs: {
      src = pkgs.fetchgit {
        rev = "362afedda5c2e011beb63ce2717fe6ab627eb2cb";
        url = "git://github.com/riscv/riscv-glibc.git";
        sha256 = "0klbn2sikfddn1iybsi8723jknp8n5imjk4byx51jszjy5msz3bv";
      };
      patches = oldAttrs.patches ++ [
        # Madness pertaining to an interaction between the Linux headers and a
        # FreeBSD compatibility hack in glibc.
        ./workaround-ptrace_getregs.patch
      ];
    });

  packageOverrides = pkgs:
    let overrideGccWithRiscvTree = drv:
          pkgs.lib.overrideDerivation drv (oldAttrs: {
            src = pkgs.fetchgit {
              rev = "879263a2c8384f9c9e679505186148fc41e40f84";
              url = "git://github.com/riscv/riscv-gcc.git";
              sha256 = "01g1idc9ksp50g215nw956y26byl2gxkz3ww5nawn480rays2ywk";
            };
            # we need flex since it's a development snapshot
            nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.flex pkgs.bison ];
            # For withFloat
            configureFlags = oldAttrs.configureFlags +
              (if withFloat then "--enable-soft-float" else "--disable-soft-float");
          });
        libcCross = toolchain.riscv-glibc;
        overrideBinutilsWithRiscvTree = drv:
          pkgs.lib.overrideDerivation drv (oldAttrs: {
            src = pkgs.fetchgit {
              rev = "407067a68ad825f82568f3741c25d3bcc186a232";
              url = "git://github.com/riscv/riscv-binutils-gdb.git";
              sha256 = "0r913gkh193xd6y40n48p6hj6vix10fakh3jwh95v8lwcbps6p5j";
            };
        });
        binutilsCross = overrideBinutilsWithRiscvTree (pkgs.forcedNativePackages.binutils.override { noSysDirs = true; cross = crossSystem; });
        gccCrossStatic = pkgs.wrapGCCCross {
          gcc = overrideGccWithRiscvTree (pkgs.forcedNativePackages.gcc6.cc.override {
            enableShared = false;
            libcCross = null;
            langCC = false;
            crossStageStatic = true;
            cross = crossSystem;
            inherit (pkgs.forcedNativePackages) binutilsCross;
          });
          libc = null;
          binutils = binutilsCross;
          cross = crossSystem;
        };
    in {
      inherit binutilsCross gccCrossStatic;
      glibcCross = pkgs.forcedNativePackages.glibc.override {
        gccCross = gccCrossStatic;
      };
      riscv-gcc = pkgs.wrapGCCCross {
        gcc = overrideGccWithRiscvTree (pkgs.forcedNativePackages.gcc6.cc.override {
          libcCross = libcCross;
          langCC = false;
          crossStageStatic = false;
          cross = crossSystem;
        });
        libc = libcCross;
        binutils = binutilsCross;
        cross = crossSystem;
      };
    };

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
  bits = "64";

  # Components of our cross-compiler toolchain
  toolchain = rec {
    linuxHeaders = pkgs.linuxHeaders_4_4;

    #riscv-newlib = import ./riscv-newlib.nix {
    #  inherit (pkgs) stdenv;
    #};

    real-glibc =
      let drv = pkgs.callPackage ./nixpkgs/pkgs/development/libraries/glibc {
          installLocales = false;
          #gccCross = gccCrossStageStatic;
          inherit linuxHeaders;
        };
      in overrideGlibc drv;
    riscv-glibc = real-glibc;

    riscv-gcc = pkgs.wrapGCCCross {
      gcc = overrideGcc real-gcc;
      libc = riscv-glibc;
      binutils = pkgs.crossBinutils;
      cross = crossSystem;
    };
    real-gcc =
      pkgs.forcedNativePackages.callPackage ./nixpkgs/pkgs/development/compilers/gcc/6 {
        inherit (pkgs) stdenv;
        cross = crossSystem;
        binutilsCross = pkgs.crossBinutils;
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

    #riscv-gdb = pkgs.lib.overrideDerivation pkgs.gdb (oldAttrs: {
    #  nativeBuildInputs = oldAttrs.nativeBuildInputs ++ [ pkgs.flex pkgs.yacc ];
    #  src = pkgs.fetchgit {
    #    rev = "2a6d6cca9bb6a900f31f2ba40e48c8e9d239b36d";
    #    url = "git://github.com/riscv/riscv-binutils-gdb.git";
    #    sha256 = "0jl36fqzlysapi1d3pm0d6wjpi1sfgq6vbbd7xw5flzh7jzcmlbw";
    #    name = "binutils";
    #  };
    #  sourceRoot = "binutils/gdb";
    #});
  };
in
  rec {
    llvm-riscv = (import ./llvm-riscv.nix {
      version = "3.8";
      inherit (pkgs) stdenv perl groff cmake python libffi binutils libxml2 valgrind ncurses zlib compiler-rt_src libcxxabi;
    });

    riscv-qemu = import ./riscv-qemu.nix {
      inherit (pkgs) stdenv autoconf automake libtool flex bison SDL zlib glib pkgconfig python;
    };

    riscv-fesvr = import ./riscv-fesvr.nix {
      inherit (pkgs) stdenv;
    };

    riscv-pk = (import ./riscv-pk.nix {
      inherit (pkgs) stdenv;
    });

    riscv-isa-sim = import ./riscv-isa-sim.nix {
      inherit riscv-fesvr;
      inherit (pkgs) stdenv;
    };

    linux-riscv = import ./linux-riscv.nix {
      inherit (pkgs) perl;
      inherit (pkgs) stdenv;
      riscv-gcc = toolchain.riscv-gcc;
    };

    riscv-libffi = (import ./libffi.nix {
      inherit (pkgs) stdenv fetchgit dejagnu autoconf automake libtool texinfo;
    });

    ncurses = import ./nixpkgs/pkgs/development/libraries/ncurses {
      inherit (pkgs) lib fetchurl pkgconfig gpm;
      inherit (pkgs) stdenv;
      abiVersion = "6";
    };

    riscv-busybox = (pkgs.busybox.override { stdenv = pkgs.stdenv;});

    #riscv-image = import ./riscv-image.nix {
    #  inherit stdenv bits linux-riscv riscv-busybox;
    #};

    inherit toolchain pkgs;
  }
