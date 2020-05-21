{ fetchFromGitHub, stdenv
, bc
, envsubst
, libnotify
, perl
, playerctl
, python3
, sysstat
, yad
}:

with stdenv.lib;

stdenv.mkDerivation {
  pname = "i3blocks-contrib";
  version = "1.5";

  src = fetchFromGitHub {
    owner = "vivien";
    repo = "i3blocks-contrib";
    rev = "d600a2c481e489bacf1118e68063ccf3750da4a1";
    sha256 = "16lka1iqp6m1n6wiv5sgqybx1agl80g3j1jkl2kk2xb4wdx4zbch";
  };

  propagatedBuildInputs = [
    bc
    envsubst
    libnotify
    perl
    playerctl
    sysstat
    yad
    (python3.withPackages (ps : [ ps.keyring ]))
  ];

  patches = [
    ./temperature.patch
  ];

  makeFlags = [ "PREFIX=$(out)" ];

  meta = {
    description = "Community-contributed blocklets for i3blocks";
    Homepage = https://github.com/vivien/i3blocks-contrib;
    license = licenses.gpl3;
    platforms = with platforms; linux;
  };
}
