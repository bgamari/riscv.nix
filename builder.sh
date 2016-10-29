source $stdenv/setup

providedPreConfigure="$preConfigure";
preConfigure() {
    echo Hello.
    # Eval the preConfigure script from nix expression.
    eval "$providedPreConfigure"

    # Perform the build in a different directory.
    mkdir ../build
    cd ../build
    configureScript=../$sourceRoot/configure
}
postConfigure() {
    # Don't store the configure flags in the resulting executables.
    sed -e '/TOPLEVEL_CONFIGURE_ARGUMENTS=/d' -i Makefile
}

genericBuild
