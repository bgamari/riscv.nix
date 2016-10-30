{ stdenv, perl, riscv-gcc }:

let
  nixpkgs = import <nixpkgs> {};
  make_flags = ;
in
  stdenv.mkDerivation rec {
    name = "linux-riscv";
    buildInputs = [perl riscv-gcc];
    patchPhase = ''
      cp ${./config-linux-4.1.y} ./.config
    '';
    buildPhase = ''
      make ARCH=riscv vmlinux ${make_flags}
      make ARCH=riscv headers_chec ${make_flags}
      make ARCH=riscv headers_instal ${make_flags}
    '';
    src = nixpkgs.fetchgit {
      # linux-4.1.y-riscv branch
      rev = "592a15184759456d9d66df8b727f7b2ec2fa8dfb";
      url = "git://github.com/riscv/riscv-linux.git";
      fetchSubmodules = true;
      sha256 = "1d2jwcmck1yli59rpk318y0aga0qpmd6sg2a5zg9wnx503rjk3l6";
    };
  }
