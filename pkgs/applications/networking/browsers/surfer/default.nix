{ stdenv, fetchFromGitHub
, pkgconfig, wrapGAppsHook
, gtk3
, webkitgtk
, glib
, glib-networking
, libsoup
, gsettings-desktop-schemas
, gconf
, patches ? null
}:

stdenv.mkDerivation rec {
  name = "surfer-${version}";
  version = "2020-05-06";

  src = fetchFromGitHub {
    owner = "nihilowy";
    repo = "surfer";
    rev = "b941a12b30b86f5f833b706f95fc48454004071c";
    sha256 = "0qbpq2s366xyrzdxsrq26pr5657i64a5iafx6x1wvx8s1f6g05pz";
  };

  postPatch = ''
  substituteInPlace Makefile --replace '$(DESTDIR)/usr' "$out"
  '';

  nativeBuildInputs = [ pkgconfig wrapGAppsHook ];
  buildInputs = [
    webkitgtk
    gtk3
    glib
    glib-networking
    libsoup
    gconf
    gsettings-desktop-schemas
  ];

  inherit patches;

  meta = with stdenv.lib; {
    description = "Simple keyboard based webkit2gtk browser";
    longDescription = ''
    Simple keyboard based web browser. No tabs.
    Based on webkit2gtk and gtk3. Lariza and Epiphany, Surf inspired.
    No xlibs dependency — works on wayland, weston, sway.
    '';
    homepage = https://github.com/nihilowy/surfer;
    license = licenses.gpl2;
    platforms = webkitgtk.meta.platforms;
  };
}
