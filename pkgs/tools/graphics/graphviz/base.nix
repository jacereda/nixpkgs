{ rev, sha256, version }:

{ stdenv, fetchFromGitLab, autoreconfHook, pkgconfig, cairo, expat, flex
, fontconfig, gd, gettext, gts, libdevil, libjpeg, libpng, libtool, pango
, yacc, fetchpatch
, x11Support ? !stdenv.isDarwin , xorg ? null
, quartzSupport ? stdenv.isDarwin, ApplicationServices ? null, libobjc ? null }:

assert stdenv.isDarwin -> ApplicationServices != null;

let
  inherit (stdenv.lib) optional optionals optionalString;
  raw_patch =
    # https://gitlab.com/graphviz/graphviz/issues/1367 CVE-2018-10196
    fetchpatch {
      name = "CVE-2018-10196.patch";
      url = https://gitlab.com/graphviz/graphviz/uploads/30f8f0b00e357c112ac35fb20241604a/p.diff;
      sha256 = "074qx6ch9blrnlilmz7p96fkiz2va84x2fbqdza5k4808rngirc7";
      excludes = ["tests/*"]; # we don't run them and they don't apply
    };
  # the patch needs a small adaption for older versions
  patch = if stdenv.lib.versionAtLeast version "2.37" then raw_patch else
  stdenv.mkDerivation {
    inherit (raw_patch) name;
    buildCommand = "sed s/dot_root/agroot/g ${raw_patch} > $out";
  };
in

stdenv.mkDerivation rec {
  pname = "graphviz";
  inherit version;

  src = fetchFromGitLab {
    owner = "graphviz";
    repo = "graphviz";
    inherit sha256 rev;
  };

  enableParallelBuilding = true;

  nativeBuildInputs = [ autoreconfHook pkgconfig ];

  buildInputs = [
    libpng libjpeg expat yacc libtool fontconfig gd gts libdevil flex pango
    gettext
  ] ++ optionals x11Support (with xorg; [ libXrender libXaw libXpm ])
    ++ optionals stdenv.isDarwin [ ApplicationServices libobjc ];

  hardeningDisable = [ "fortify" ];

  CPPFLAGS = optionalString (x11Support && stdenv.isDarwin)
    "-I${cairo.dev}/include/cairo";

  configureFlags = [
    "--with-ltdl-lib=${libtool.lib}/lib"
    "--with-ltdl-include=${libtool}/include"
  ] ++ optional (!x11Support) "--without-x"
    ++ optional quartzSupport "--with-quartz";

  patches = [
    patch
  ];

  postPatch = ''
    for f in $(find . -name Makefile.in); do
      substituteInPlace $f --replace "-lstdc++" "-lc++"
    done
  '' + optionalString stdenv.isDarwin ''
    substituteInPlace plugin/quartz/Makefile.am \
      --replace 'WITH_DARWIN9' '!WITH_DARWIN9' \
      --replace 'AM_LIBTOOLSFLAGS' 'AM_LIBTOOLFLAGS'
  '';

  # ''
  #   substituteInPlace rtest/rtest.sh \
  #     --replace "/bin/ksh" "${mksh}/bin/mksh"
  # '';

  doCheck = false; # fails with "Graphviz test suite requires ksh93" which is not in nixpkgs

  preAutoreconf = "./autogen.sh";

  postFixup = optionalString x11Support ''
    substituteInPlace $out/bin/dotty --replace '`which lefty`' $out/bin/lefty
    substituteInPlace $out/bin/vimdot \
      --replace /usr/bin/vi '$(command -v vi)' \
      --replace /usr/bin/vim '$(command -v vim)' \
      --replace /usr/bin/vimdot $out/bin/vimdot \
  '';

  meta = with stdenv.lib; {
    homepage = https://graphviz.org;
    description = "Graph visualization tools";
    license = licenses.epl10;
    platforms = platforms.unix;
    maintainers = with maintainers; [ bjornfor raskin ];
  };
}
