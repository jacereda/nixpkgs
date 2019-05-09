{ stdenv

# Build time
, fetchgit, fetchpatch, pkgconfig, perl, texinfo, setupDebugInfoDirs, buildPackages
, bison, flex # Only needed in non-release versions

# Run time
, ncurses, readline, gmp, mpfr, expat, zlib, dejagnu

, pythonSupport ? stdenv.hostPlatform == stdenv.buildPlatform && !stdenv.hostPlatform.isCygwin, python3 ? null
, guile ? null

}:

let
  basename = "gdb-${version}";
  version = "8.3pre";
in

assert pythonSupport -> python3 != null;

stdenv.mkDerivation rec {
  name =
    stdenv.lib.optionalString (stdenv.targetPlatform != stdenv.hostPlatform)
                              (stdenv.targetPlatform.config + "-")
    + basename;

  src = fetchgit {
    url = "http://sourceware.org/git/binutils-gdb.git";
    sha256 = "04qz0dblxv1yssk5bwz8nwn6y3ry26vl1lk78zq3ikk3822sba8q";
    rev = "353ea2d106a51cfd1680f7d351f35eb8f69c9248";
  };

  patches = [
    ./debug-info-from-env.patch
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    ./darwin-target-match.patch
  ];

  postPatch = ''
    substituteInPlace gdb/darwin-nat.c --replace 'bfd/mach-o.h' 'mach-o.h'
  '';

  nativeBuildInputs = [ pkgconfig texinfo perl setupDebugInfoDirs bison flex ];

  buildInputs = [ ncurses readline gmp mpfr expat zlib guile ]
    ++ stdenv.lib.optional pythonSupport python3
    ++ stdenv.lib.optional doCheck dejagnu;

  propagatedNativeBuildInputs = [ setupDebugInfoDirs ];

  depsBuildBuild = [ buildPackages.stdenv.cc ];

  enableParallelBuilding = true;

  # darwin build fails with format hardening since v7.12
  hardeningDisable = stdenv.lib.optionals stdenv.isDarwin [ "format" ];

  NIX_CFLAGS_COMPILE = "-Wno-format-nonliteral";

  # TODO(@Ericson2314): Always pass "--target" and always prefix.
  configurePlatforms = [ "build" "host" ] ++ stdenv.lib.optional (stdenv.targetPlatform != stdenv.hostPlatform) "target";

  configureFlags = with stdenv.lib; [
    "--enable-targets=all" "--enable-64-bit-bfd"
    "--disable-install-libbfd"
    "--disable-shared" "--enable-static"
    "--with-system-zlib"
    "--with-system-readline"
    "--disable-werror"

    "--with-gmp=${gmp.dev}"
    "--with-mpfr=${mpfr.dev}"
    "--with-expat" "--with-libexpat-prefix=${expat.dev}"
  ] ++ stdenv.lib.optional (!pythonSupport) "--without-python";

  postInstall =
    '' # Remove Info files already provided by Binutils and other packages.
       rm -v $out/share/info/bfd.info
    '';

  # TODO: Investigate & fix the test failures.
  doCheck = false;

  meta = with stdenv.lib; {
    description = "The GNU Project debugger";

    longDescription = ''
      GDB, the GNU Project debugger, allows you to see what is going
      on `inside' another program while it executes -- or what another
      program was doing at the moment it crashed.
    '';

    homepage = https://www.gnu.org/software/gdb/;

    license = stdenv.lib.licenses.gpl3Plus;

    platforms = with platforms; linux ++ cygwin ++ darwin;
  };
}
