{ stdenv, lib, fetchurl, alsaLib, atk, cairo, cups, udev
, dbus, expat, fontconfig, freetype, gdk-pixbuf, glib, gtk3, libappindicator-gtk3
, libnotify, nspr, nss, pango, systemd, xorg, autoPatchelfHook, wrapGAppsHook
, runtimeShell, gsettings-desktop-schemas }:

let
  versionSuffix = "20201016183637.d4ebf7d999";
in

stdenv.mkDerivation rec {
  pname = "keybase-gui";
  version = "5.5.2"; # Find latest version from https://prerelease.keybase.io/deb/dists/stable/main/binary-amd64/Packages

  src = fetchurl {

    url = "https://s3.amazonaws.com/prerelease.keybase.io/linux_binaries/deb/keybase_${version + "-" + versionSuffix}_amd64.deb";
    sha256 = "0qwbqnc6dhfnx3gdwl1lyhdsbclaxpkv3zr3dmxfx1242s64v0c1";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook
  ];

  buildInputs = [
    alsaLib
    atk
    cairo
    cups
    dbus
    expat
    fontconfig
    freetype
    gdk-pixbuf
    glib
    gsettings-desktop-schemas
    gtk3
    libappindicator-gtk3
    libnotify
    nspr
    nss
    pango
    systemd
    xorg.libX11
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst
    xorg.libxcb
  ];

  runtimeDependencies = [
    (lib.getLib udev)
    libappindicator-gtk3
  ];

  dontBuild = true;
  dontConfigure = true;
  dontPatchELF = true;

  unpackPhase = ''
    ar xf $src
    tar xf data.tar.xz
  '';

  installPhase = ''
    mkdir -p $out/bin
    mv usr/share $out/share
    mv opt/keybase $out/share/

    cat > $out/bin/keybase-gui <<EOF
    #!${runtimeShell}

    checkFailed() {
      if [ "\$NIX_SKIP_KEYBASE_CHECKS" = "1" ]; then
        return
      fi
      echo "Set NIX_SKIP_KEYBASE_CHECKS=1 if you want to skip this check." >&2
      exit 1
    }

    if [ ! -S "\$XDG_RUNTIME_DIR/keybase/keybased.sock" ]; then
      echo "Keybase service doesn't seem to be running." >&2
      echo "You might need to run: keybase service" >&2
      checkFailed
    fi

    if [ -z "\$(keybase status | grep kbfsfuse)" ]; then
      echo "Could not find kbfsfuse client in keybase status." >&2
      echo "You might need to run: kbfsfuse" >&2
      checkFailed
    fi

    exec $out/share/keybase/Keybase "\$@"
    EOF
    chmod +x $out/bin/keybase-gui

    substituteInPlace $out/share/applications/keybase.desktop \
      --replace run_keybase $out/bin/keybase-gui
  '';

  meta = with stdenv.lib; {
    homepage = "https://www.keybase.io/";
    description = "The Keybase official GUI";
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ avaq rvolosatovs puffnfresh np Br1ght0ne ];
    license = licenses.bsd3;
  };
}
