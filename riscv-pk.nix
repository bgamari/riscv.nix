{ stdenv }:

let
  nixpkgs = import <nixpkgs> {};
in
  stdenv.mkDerivation rec {
    name = "riscv-pk";
    src = nixpkgs.fetchgit {
      rev = "7a7106885367201ffbfd6f5568d8c5262dbb766d";
      url = "git://github.com/riscv/riscv-pk.git";
      sha256 = "14n7dzcihihpllamkcn8ya8zkvfpspp1qakysdbvjc6hn4nypg9z";
    };

    # We can't run the build in the source tree due to dummy_payload being both
    # the name of a target and a directory.
    preConfigure = ''
      mkdir build
      cd build
    '';
    configureScript="../configure";
  }
