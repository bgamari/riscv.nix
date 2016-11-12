{ bits, stdenv, linux-riscv, riscv-busybox }:

stdenv.mkDerivation rec {
  name = "riscv-image";
  buildInputs = [ linux-riscv ];
  srcs = [
    fetchurl("http://riscv.org/install-guides/linux-inittab")
  ];
  buildPhase = "";
  installPhase = ''
    mkdir -p root
    cp ${linux-riscv}/arch/riscv/vmlinux vmlinux
    cd root
    mkdir -p bin etc dev lib proc sbin sys tmp usr usr/bin usr/lib usr/sbin
    cp ${linux-inittab} etc/inittab
    cd ..
    mksquashfs root root.bin.sqsh
  '';
}
