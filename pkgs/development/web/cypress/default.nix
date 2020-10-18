{ stdenv, lib, fetchzip, autoPatchelfHook, xorg, gtk2, gnome2, gtk3, nss, alsaLib, udev, unzip, wrapGAppsHook }:

stdenv.mkDerivation rec {
  pname = "cypress";
  version = "5.3.0";

  src = fetchzip {
    url = "https://cdn.cypress.io/desktop/${version}/linux-x64/cypress.zip";
    sha256 = "0f3sw71ridpwcy0m8xl9gs76zl9zfsrfwzbqjidvlnszvx3177bl";
  };

  # don't remove runtime deps
  dontPatchELF = true;

  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook ];

  buildInputs = with xorg; [
    libXScrnSaver libXdamage libXtst
  ] ++ [
    nss gtk2 alsaLib gnome2.GConf gtk3 unzip
  ];

  runtimeDependencies = [ (lib.getLib udev) ];

  installPhase = ''
    mkdir -p $out/bin $out/opt/cypress
    cp -vr * $out/opt/cypress/
    # Let's create the file binary_state ourselves to make the npm package happy on initial verification.
    # Cypress now verifies version by reading bin/resources/app/package.json
    mkdir -p $out/bin/resources/app
    printf '{"version":"%b"}' $version > $out/bin/resources/app/package.json
    # Cypress now looks for binary_state.json in bin
    echo '{"verified": true}' > $out/binary_state.json
    ln -s $out/opt/cypress/Cypress $out/bin/Cypress
  '';

  meta = with stdenv.lib; {
    description = "Fast, easy and reliable testing for anything that runs in a browser";
    homepage = "https://www.cypress.io";
    license = licenses.mit;
    platforms = ["x86_64-linux"];
    maintainers = with maintainers; [ tweber mmahut ];
  };
}
