{ stdenv, lib, fetchFromGitHub, scons, pkgconfig
, useX11? !stdenv.isDarwin, libX11, libXcursor , libXinerama, libXrandr, libXrender, libXi, libXext, libXfixes, libGLU
, libpulseaudio
, freetype, openssl
, alsaLib, zlib, yasm
, Cocoa, Carbon, OpenGL, AGL, AudioUnit, CoreAudio, CoreMIDI, IOKit, ForceFeedback, AVFoundation, CoreMedia, CoreVideo, xcbuild
}:

let
  options = {
    touch = libXi != null;
    pulseaudio = false;
  };
in stdenv.mkDerivation rec {
  pname = "godot";
  version = "3.1.1";

  src = fetchFromGitHub {
    owner  = "godotengine";
    repo   = "godot";
    rev    = "${version}-stable";
    sha256 = "0lplkwgshh0x7r1daai9gflzwjnp3yfx4724h1myvidaz234v2wh";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [
    scons freetype openssl libpulseaudio zlib yasm
  ] ++ stdenv.lib.optionals useX11 [
    libX11 libXcursor libXinerama libXrandr libXrender
    libXi libXext libXfixes libGLU
  ] ++ stdenv.lib.optionals stdenv.isLinux [
    alsaLib
  ] ++ stdenv.lib.optionals stdenv.isDarwin [
    Cocoa Carbon OpenGL AGL AudioUnit CoreAudio CoreMIDI IOKit ForceFeedback AVFoundation CoreMedia CoreVideo
  ];

  patches = [
    ./pkg_config_additions.patch
    ./dont_clobber_environment.patch
  ];

  enableParallelBuilding = true;

  sconsFlags = "target=release_debug platform=x11";
  preConfigure = ''
    sconsFlags+=" ${lib.concatStringsSep " " (lib.mapAttrsToList (k: v: "${k}=${builtins.toJSON v}") options)}"
  '';

  outputs = [ "out" "dev" "man" ];

  installPhase = ''
    mkdir -p "$out/bin"
    cp bin/godot.* $out/bin/godot

    mkdir "$dev"
    cp -r modules/gdnative/include $dev

    mkdir -p "$man/share/man/man6"
    cp misc/dist/linux/godot.6 "$man/share/man/man6/"

    mkdir -p "$out"/share/{applications,icons/hicolor/scalable/apps}
    cp misc/dist/linux/org.godotengine.Godot.desktop "$out/share/applications/"
    cp icon.svg "$out/share/icons/hicolor/scalable/apps/godot.svg"
    cp icon.png "$out/share/icons/godot.png"
    substituteInPlace "$out/share/applications/org.godotengine.Godot.desktop" \
      --replace "Exec=godot" "Exec=$out/bin/godot"
  '';

  meta = {
    homepage    = "https://godotengine.org";
    description = "Free and Open Source 2D and 3D game engine";
    license     = stdenv.lib.licenses.mit;
    platforms   = [ "i686-linux" "x86_64-linux" "x86_64-darwin"];
    maintainers = [ stdenv.lib.maintainers.twey ];
  };
}
