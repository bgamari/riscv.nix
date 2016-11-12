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
      rev = "b12cfa344681687c7adbc5fa66590182df3748b9";
      url = "git://github.com/riscv/riscv-qemu.git";
      sha256 = "15pcl936ppfk57bylfyshhz01yink1khz54iwispa1g64smfn803";
    };
  }
