{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "linux-riscv";
    builder = ''
      make ARCH=riscv headers_check && \
      make ARCH=riscv INSTALL_HDR_PATH=$RISCV/riscv-tools/riscv-gnu-toolchain/linux-headers headers_install
    '';
    src = nixpkgs.fetchgit {
      # linux-4.1.y-riscv branch
      rev = "592a15184759456d9d66df8b727f7b2ec2fa8dfb";
      url = "git://github.com/riscv/riscv-linux.git";
      fetchSubmodules = true;
      sha256 = "0jlj0vhmxxl2w9xjzhdcl4k1p3dgq93npqpqkjg7qcngpjlmifd2";
    };
  }
