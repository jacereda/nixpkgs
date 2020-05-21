{ stdenv, lib, fetchFromGitHub }:

stdenv.mkDerivation rec {
  pname = "mbpfan";
  #  version = "2.2.1";
  version = "2.2.2-git";
  src = fetchFromGitHub {
    owner = "dgraziotin";
    repo = "mbpfan";
    #    rev = "v${version}";
    rev = "bc71232af281e73f9c47d1b45fcb6ae284daf480";
    sha256 = "101i00w7nl9drjxi5da2zm9qlvn6j9la3pkakm87pc71bbvrdj3b";
  };
  installPhase = ''
    mkdir -p $out/bin $out/etc
    cp bin/mbpfan $out/bin
    cp mbpfan.conf $out/etc
  '';
  meta = with lib; {
    description = "Daemon that uses input from coretemp module and sets the fan speed using the applesmc module";
    homepage = "https://github.com/dgraziotin/mbpfan";
    license = licenses.gpl3;
    platforms = platforms.linux;
    maintainers = with maintainers; [ cstrahan ];
  };
}
