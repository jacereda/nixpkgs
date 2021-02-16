{ lib
, stdenv
, fetchurl
, ncurses
, withLibrary ? false, libtool
, unicodeSupport ? true
, enableShared ? !stdenv.isDarwin
}:

assert withLibrary -> libtool != null;
assert unicodeSupport -> ncurses.unicode && ncurses != null;

stdenv.mkDerivation rec {
  pname = "dialog";
  version = "1.3-20210117";

  src = fetchurl {
    url = "ftp://ftp.invisible-island.net/dialog/${pname}-${version}.tgz";
    sha256 = "PB7Qj0S89vFZ8qpv3nZduU6Jl7Pu+0nYtMhmkWk8Q+E=";
  };

  buildInputs = [ ncurses ];

  configureFlags = [
    "--disable-rpath-hacks"
    (lib.withFeature withLibrary "libtool")
    "--with-ncurses${lib.optionalString unicodeSupport "w"}"
    "--with-libtool-opts=${lib.optionalString enableShared "-shared"}"
  ];

  installTargets = [ "install${lib.optionalString withLibrary "-full"}" ];

  meta = with lib; {
    homepage = "https://invisible-island.net/dialog/dialog.html";
    description = "Display dialog boxes from shell";
    license = licenses.lgpl21Plus;
    maintainers = with maintainers; [ AndersonTorres spacefrogg ];
    platforms = ncurses.meta.platforms;
  };
}
