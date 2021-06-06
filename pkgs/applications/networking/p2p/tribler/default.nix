{ stdenv, fetchurl, python3Packages, makeWrapper
, enablePlayer ? false, libvlc, qt5, lib }:

stdenv.mkDerivation rec {
  pname = "tribler";
  version = "7.9.0";

  src = fetchurl {
    url = "https://github.com/Tribler/tribler/releases/download/v${version}/Tribler-v${version}.tar.xz";
    sha256 = "1icvrbpfilb2zn66c2ri0b938hs4mbfmijdr2bxph0003xaszhac";
  };

  nativeBuildInputs = [
    python3Packages.wrapPython
    makeWrapper
  ];

  buildInputs = [
    python3Packages.python
  ];

  pythonPath = with python3Packages; [
    libtorrent-rasterbar-1_2_x
    twisted
    netifaces
    pycrypto
    pyasn1
    requests
    m2crypto
    pyqt5
    chardet
    cherrypy
    cryptography
    libnacl
    configobj
    decorator
    feedparser
    service-identity
    psutil
    pillow
    networkx
    pony
    lz4
    pyqtgraph
    faker
    sentry-sdk
    yappi
    aiohttp
    aiohttp-apispec
    pyyaml
    marshmallow


    # there is a BTC feature, but it requires some unclear version of
    # bitcoinlib, so this doesn't work right now.
    # bitcoinlib
  ];

  installPhase = ''
    mkdir -pv $out
    # Nasty hack; call wrapPythonPrograms to set program_PYTHONPATH.
    wrapPythonPrograms
    cp -prvd ./src/* $out/
    makeWrapper ${python3Packages.python}/bin/python $out/bin/tribler \
        --set QT_QPA_PLATFORM_PLUGIN_PATH ${qt5.qtbase.bin}/lib/qt-*/plugins/platforms \
        --set TRIBLE_DIR $out \
        --set PYTHONPATH $out:$out/pyipv8:$out/anydex:$out/tribler-common:$out/tribler-core:$out/tribler-gui:$program_PYTHONPATH \
        --set NO_AT_BRIDGE 1 \
        --run 'cd $_TRIBLERPATH' \
        --add-flags "-O $out/run_tribler.py" \
        ${lib.optionalString enablePlayer ''
          --prefix LD_LIBRARY_PATH : ${libvlc}/lib
        ''}

    mkdir -p $out/share/applications $out/share/icons $out/share/man/man1
  '';

  meta = with lib; {
    maintainers = with maintainers; [ xvapx ];
    homepage = "https://www.tribler.org/";
    description = "A completely decentralised P2P filesharing client based on the Bittorrent protocol";
    license = licenses.lgpl21;
    platforms = platforms.linux;
  };
}
