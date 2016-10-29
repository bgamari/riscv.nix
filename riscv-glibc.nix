{ bits, atomic ? true, float ? true, stdenv, gmp, mpfr, libmpc, riscv-gcc-stage1 }:

# TODO: float switch
let
  nixpkgs = import <nixpkgs> {};
  noatomic = if !atomic then "-mno-atomic" else "" + " ";
  cflags = if bits == 32 then "-m32" else "" + " " + noatomic;
  asflags = noatomic;
  #cc = "riscv${bits}-unknown-linux-gnu-gcc " + noatomic + " -m${bits}";
  cc = "riscv${bits}-unknown-linux-gnu-gcc";
  readelf = "riscv${bits}-unknown-linux-gnu-readelf";
in
  stdenv.mkDerivation rec {
    name = "riscv-glibc";
    buildInputs = [ gmp mpfr libmpc riscv-gcc-stage1 ];
    configureFlags = [
      "--host=riscv${bits}-unknown-linux-gnu"
      "CC=\"${cc}\""
      "READELF=${readelf}"
      "CFLAGS=${cflags}"
      "ASFLAGS=${asflags}"
      "--disable-werror"
      "--enable-shared"
      "--enable-__thread"
      "libc_cv_forced_unwind=yes"
      "libc_cv_c_cleanup=yes"
    ];
    src = nixpkgs.fetchgit {
      rev = "f02ec12b5e5945b9fe6e4f46fe48f13a66dd0b97";
      url = "git://github.com/riscv/riscv-glibc.git";
      sha256 = "16an18mk3hr0qmpv0lqir229d0ikj9m4n6a3q9x9raswn1sf1iyi";
    };
  }
