{ bits, cross, atomic ? true, float ? true, stdenv, gmp, mpfr, libmpc, riscv-gcc-stage1, riscv-binutils, linuxHeaders }:

# TODO: float switch
let
  nixpkgs = import <nixpkgs> {};
  noatomic = if !atomic then "-mno-atomic" else "" + " ";
  cflags = if bits == 32 then "-m32" else "" + " " + noatomic;
  asflags = noatomic;
in
  stdenv.mkDerivation rec {
    inherit linuxHeaders;
    name = "riscv-glibc";
    nativeBuildInputs = [ gmp mpfr libmpc riscv-gcc-stage1 riscv-binutils linuxHeaders ];
    enableParallelBuilding = true;
    patches = [
      # Madness pertaining to an interaction between the Linux headers and a
      # FreeBSD compatibility hack in glibc.
      ./workaround-ptrace_getregs.patch
    ];
    crossConfig = cross.config;

    configureFlags = [
      "--host=riscv${bits}-unknown-linux-gnu"
      "--disable-werror"
      "--enable-shared"
      "--enable-__thread"
      "libc_cv_forced_unwind=yes"
      "libc_cv_c_cleanup=yes"
      "--enable-kernel=2.6.32"
      "CC=riscv${bits}-unknown-linux-gnu-gcc"
      "AS=riscv${bits}-unknown-linux-gnu-as"
      "AR=riscv${bits}-unknown-linux-gnu-ar"
      "RANLIB=riscv${bits}-unknown-linux-gnu-ranlib"
      "--with-headers=${linuxHeaders}/include"
    ];
    src = nixpkgs.fetchgit {
      rev = "f02ec12b5e5945b9fe6e4f46fe48f13a66dd0b97";
      url = "git://github.com/riscv/riscv-glibc.git";
      sha256 = "16an18mk3hr0qmpv0lqir229d0ikj9m4n6a3q9x9raswn1sf1iyi";
    };

    postConfigure = ''
      # Hack: get rid of the `-static' flag set by the bootstrap stdenv.
      # This has to be done *after* `configure' because it builds some
      # test binaries.
      export NIX_CFLAGS_LINK=
      export NIX_LDFLAGS_BEFORE=

      export NIX_DONT_SET_RPATH=1
      unset CFLAGS

      # Apparently --bindir is not respected.
      makeFlagsArray+=("bindir=$bin/bin" "sbindir=$bin/sbin" "rootsbindir=$bin/sbin")
    '';

    # Perform the build in a different directory.
    configurePhase = ''
      mkdir build
      cd build
      ../configure --prefix=$prefix ${builtins.concatStringsSep " " configureFlags}
    '';
  }
