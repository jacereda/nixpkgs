{ stdenv
, boehmgc
, boost
, cairo
, cmake
, fetchpatch
, fetchurl
, gettext
, glib
, glibmm
, gsl
, gtkmm2
, gtkspell2
, imagemagick
, lcms
, libcdr
, libexif
, libpng
, librevenge
, librsvg
, libsigcxx
, libvisio
, libwpg
, libXft
, libxml2
, libxslt
, makeWrapper
, perlPackages
, pkg-config
, poppler
, popt
, potrace
, python3
, wrapGAppsHook
, zlib
, x11Support ? (!stdenv.isDarwin)
}:
let
  python3Env = python3.withPackages
    (ps: with ps; [
      numpy
      lxml
      scour
    ]);
in
stdenv.mkDerivation rec {
  pname = "inkscape";
  version = "0.92.5";

  src = fetchurl {
    url = "https://media.inkscape.org/dl/resources/file/${pname}-${version}.tar.bz2";
    sha256 = "02wsa66ifycibmgfsrhmhqdv41brg955lffq8drsjr5xw9lpzvl1";
  };

  # Inkscape hits the ARGMAX when linking on macOS. It appears to be
  # CMake’s ARGMAX check doesn’t offer enough padding for NIX_LDFLAGS.
  # Setting strictDeps it avoids duplicating some dependencies so it
  # will leave us under ARGMAX.
  strictDeps = true;

  postPatch = ''
    patchShebangs share/extensions
    patchShebangs fix-roff-punct

    # Python is used at run-time to execute scripts, e.g., those from
    # the "Effects" menu.
    substituteInPlace src/extension/implementation/script.cpp \
      --replace '"python-interpreter", "python"' '"python-interpreter", "${python3Env}/bin/python"'
  '';

  cmakeFlags = [
    "-DWITH_GTK3_EXPERIMENTAL=ON"
    ];
  nativeBuildInputs = [
    pkg-config
    cmake
    makeWrapper
    python3Env
    wrapGAppsHook
  ] ++ (with perlPackages; [
    perl
    XMLParser
  ]);

  buildInputs = [
    boehmgc
    boost
    gettext
    glib
    glibmm
    gsl
    gtkmm2
    imagemagick
    lcms
    libcdr
    libexif
    libpng
    librevenge
    librsvg # for loading icons
    libsigcxx
    libvisio
    libwpg
    libXft
    libxml2
    libxslt
    perlPackages.perl
    poppler
    popt
    potrace
    python3Env
    zlib
  ] ++ stdenv.lib.optional x11Support [
    libXft
  ] ++ stdenv.lib.optionals (!stdenv.isDarwin) [
    gtkspell2
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    cairo
  ] ++ stdenv.lib.optional (!stdenv.isDarwin) gtkspell2
    ++ stdenv.lib.optional stdenv.isDarwin cairo;

  # Make sure PyXML modules can be found at run-time.
  postInstall = stdenv.lib.optionalString stdenv.isDarwin ''
    install_name_tool -change $out/lib/libinkscape_base.dylib $out/lib/inkscape/libinkscape_base.dylib $out/bin/inkscape
    install_name_tool -change $out/lib/libinkscape_base.dylib $out/lib/inkscape/libinkscape_base.dylib $out/bin/inkview
  '';

  meta = with stdenv.lib; {
    description = "Vector graphics editor";
    homepage = "https://www.inkscape.org";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.jtojnar ];
    platforms = platforms.all;
    longDescription = ''
      Inkscape is a feature-rich vector graphics editor that edits
      files in the W3C SVG (Scalable Vector Graphics) file format.

      If you want to import .eps files install ps2edit.
    '';
  };
}
