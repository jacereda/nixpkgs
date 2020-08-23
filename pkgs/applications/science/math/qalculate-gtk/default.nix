{ stdenv, fetchFromGitHub, intltool, autoreconfHook, pkgconfig, libqalculate, gtk3, wrapGAppsHook }:

stdenv.mkDerivation rec {
  pname = "qalculate-gtk";
  version = "3.12.1";

  src = fetchFromGitHub {
    owner = "qalculate";
    repo = "qalculate-gtk";
    rev = "v${version}";
    sha256 = "0ylsxj9rn3dc1grn9w6jisci3ak0hxgbwzqp54azs3aj5cmvkfgg";
  };

  patchPhase = ''
    # https://github.com/Qalculate/qalculate-gtk/pull/178
    substituteInPlace configure.ac --replace 'libxml-2.0' 'libxml-2.0 gio-unix-2.0'

    # https://github.com/Qalculate/qalculate-gtk/pull/179
    echo searchprovider.o: gnome-search-provider2.c >>src/Makefile.am
  '';

  hardeningDisable = [ "format" ];

  nativeBuildInputs = [ intltool pkgconfig autoreconfHook wrapGAppsHook ];
  buildInputs = [ libqalculate gtk3 ];
  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "The ultimate desktop calculator";
    homepage = "http://qalculate.github.io";
    maintainers = with maintainers; [ gebner ];
    license = licenses.gpl2Plus;
    platforms = platforms.all;
  };
}
