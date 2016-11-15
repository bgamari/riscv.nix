{ fetchgit, stdenv, autoconf, automake, libtool, texinfo, dejagnu, doCheck ? false }:

stdenv.mkDerivation rec {
  name = "libffi-3.99999";

  src = fetchgit {
    rev = "5a57b2a26ad2cd8a729dd2046226745a33336bed";
    url = "git://github.com/sorear/libffi-riscv.git";
    sha256 = "1z4f97nl8bs5k04q8kp82wwkicqsf21by49qvnvq1mf4j4njrk9p";
  };

  outputs = [ "out" "dev" "doc" ];

  nativeBuildInputs = [ autoconf automake libtool texinfo ];
  buildInputs = stdenv.lib.optional doCheck dejagnu;

  preConfigure = "./autogen.sh";
  configureFlags = [
    "--with-gcc-arch=generic" # no detection of -march= or -mtune=
    "--enable-pax_emutramp"
  ];

  inherit doCheck;

  dontStrip = stdenv ? cross; # Don't run the native `strip' when cross-compiling.

  # Install headers and libs in the right places.
  postFixup = ''
    mkdir -p "$dev/"
    mv "$out/lib/${name}/include" "$dev/include"
    rmdir "$out/lib/${name}"
    substituteInPlace "$dev/lib/pkgconfig/libffi.pc" \
      --replace 'includedir=''${libdir}/libffi-99999' "includedir=$dev"
  '';

  meta = with stdenv.lib; {
    description = "A foreign function call interface library";
    longDescription = ''
      The libffi library provides a portable, high level programming
      interface to various calling conventions.  This allows a
      programmer to call any function specified by a call interface
      description at run-time.

      FFI stands for Foreign Function Interface.  A foreign function
      interface is the popular name for the interface that allows code
      written in one language to call code written in another
      language.  The libffi library really only provides the lowest,
      machine dependent layer of a fully featured foreign function
      interface.  A layer must exist above libffi that handles type
      conversions for values passed between the two languages.
    '';
    homepage = http://sourceware.org/libffi/;
    # See http://github.com/atgreen/libffi/blob/master/LICENSE .
    license = licenses.free;
    maintainers = [ ];
    platforms = platforms.all;
  };
}
