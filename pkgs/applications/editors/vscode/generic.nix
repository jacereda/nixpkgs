{ stdenv, lib, makeDesktopItem
, unzip, wrapGAppsHook
, x11Support ? (!stdenv.isDarwin) , libXScrnSaver, libsecret
, gtk2, atomEnv, at-spi2-atk, autoPatchelfHook
, systemd, fontconfig

# Attributes inherit from specific versions
, version, src, meta, sourceRoot
, executableName, longName, shortName, pname
}:

let
  inherit (stdenv.hostPlatform) system;
in
  stdenv.mkDerivation rec {

    inherit pname version src sourceRoot;

    passthru = {
      inherit executableName;
    };

    desktopItem = makeDesktopItem {
      name = executableName;
      desktopName = longName;
      comment = "Code Editing. Redefined.";
      genericName = "Text Editor";
      exec = executableName;
      icon = "@out@/share/pixmaps/code.png";
      startupNotify = "true";
      categories = "Utility;TextEditor;Development;IDE;";
      mimeType = "text/plain;inode/directory;";
      extraEntries = ''
        StartupWMClass=${shortName}
        Actions=new-empty-window;
        Keywords=vscode;

        [Desktop Action new-empty-window]
        Name=New Empty Window
        Exec=${executableName} --new-window %F
        Icon=@out@/share/pixmaps/code.png
      '';
    };

    urlHandlerDesktopItem = makeDesktopItem {
      name = executableName + "-url-handler";
      desktopName = longName + " - URL Handler";
      comment = "Code Editing. Redefined.";
      genericName = "Text Editor";
      exec = executableName + " --open-url %U";
      icon = "@out@/share/pixmaps/code.png";
      startupNotify = "true";
      categories = "Utility;TextEditor;Development;IDE;";
      mimeType = "x-scheme-handler/vscode;";
      extraEntries = ''
        NoDisplay=true
        Keywords=vscode;
      '';
    };

    buildInputs = (if stdenv.isDarwin
      then [ unzip ]
      else [ gtk2 at-spi2-atk wrapGAppsHook ] ++ atomEnv.packages)
        ++ lib.optionals x11Support [ libsecret libXScrnSaver ];

    nativeBuildInputs = lib.optional (!stdenv.isDarwin) autoPatchelfHook;

    dontBuild = true;
    dontConfigure = true;

    installPhase =
      if system == "x86_64-darwin" then ''
        mkdir -p $out/lib/vscode $out/bin
        cp -r ./* $out/lib/vscode
        ln -s $out/lib/vscode/Contents/Resources/app/bin/${executableName} $out/bin
      '' else ''
        mkdir -p $out/lib/vscode $out/bin
        cp -r ./* $out/lib/vscode

        substituteInPlace $out/lib/vscode/bin/${executableName} --replace '"$CLI" "$@"' '"$CLI" "--skip-getting-started" "$@"'

        ln -s $out/lib/vscode/bin/${executableName} $out/bin

        mkdir -p $out/share/applications
        substitute $desktopItem/share/applications/${executableName}.desktop $out/share/applications/${executableName}.desktop \
          --subst-var out
        substitute $urlHandlerDesktopItem/share/applications/${executableName}-url-handler.desktop $out/share/applications/${executableName}-url-handler.desktop \
          --subst-var out

        mkdir -p $out/share/pixmaps
        cp $out/lib/vscode/resources/app/resources/linux/code.png $out/share/pixmaps/code.png

        # Override the previously determined VSCODE_PATH with the one we know to be correct
        sed -i "/ELECTRON=/iVSCODE_PATH='$out/lib/vscode'" $out/bin/${executableName}
        grep -q "VSCODE_PATH='$out/lib/vscode'" $out/bin/${executableName} # check if sed succeeded
      '';

    preFixup = lib.optionalString (system == "i686-linux" || system == "x86_64-linux") ''
      gappsWrapperArgs+=(--prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ systemd fontconfig ]})
    '';

    inherit meta;
  }
