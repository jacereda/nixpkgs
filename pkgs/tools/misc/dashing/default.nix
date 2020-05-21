# This file was generated by https://github.com/kamilchm/go2nix v1.2.1
{ stdenv, buildGoPackage, fetchgit }:

buildGoPackage rec {
  pname = "dashing-unstable";
  version = "2018-02-15";
  rev = "0e0519d76ed6bbbe02b00ee1d1ac24697d349f49";

  goPackagePath = "github.com/technosophos/dashing";

  src = fetchgit {
    inherit rev;
    url = "https://github.com/technosophos/dashing";
    sha256 = "066njyk3c1fqqr0v6aa6knp3dnksmh6hnl9d84fgd4wzyw3ma2an";
  };

  goDeps = ./deps.nix;

  meta = with stdenv.lib; {
    description = "A Dash Generator Script for Any HTML";
    homepage    = "https://github.com/technosophos/dashing";
    license     = licenses.mit;
    maintainers = [ ];
    platforms   = platforms.all;
  };
}
