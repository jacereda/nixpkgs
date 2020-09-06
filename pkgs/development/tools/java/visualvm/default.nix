{ stdenv, fetchzip, lib, makeWrapper, makeDesktopItem, jdk, gawk }:

stdenv.mkDerivation rec {
  version = "2.0.4";
  pname = "visualvm";

  src = fetchzip {
    url = "https://github.com/visualvm/visualvm.src/releases/download/${version}/visualvm_${builtins.replaceStrings ["."] [""]  version}.zip";
    sha256 = "1ic6gjsw90j7pr1yyplmk1zc319ld49i6d4zlgs7mlz1m4bn5jv3";
  };

  desktopItem = makeDesktopItem {
      name = "visualvm";
      exec = "visualvm";
      comment = "Java Troubleshooting Tool";
      desktopName = "VisualVM";
      genericName = "Java Troubleshooting Tool";
      categories = "Development;";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    find . -type f -name "*.dll" -o -name "*.exe"  -delete;

    substituteInPlace etc/visualvm.conf \
      --replace "#visualvm_jdkhome=" "visualvm_jdkhome=" \
      --replace "/path/to/jdk" "${jdk.home}" \

    substituteInPlace platform/lib/nbexec \
      --replace /usr/bin/\''${awk} ${gawk}/bin/awk

    cp -r . $out
  '';

  meta = with stdenv.lib; {
    description = "A visual interface for viewing information about Java applications";
    longDescription = ''
      VisualVM is a visual tool integrating several commandline JDK
      tools and lightweight profiling capabilities. Designed for both
      production and development time use, it further enhances the
      capability of monitoring and performance analysis for the Java
      SE platform.
    '';
    homepage = "https://visualvm.github.io";
    license = licenses.gpl2ClasspathPlus;
    platforms = platforms.all;
    maintainers = with maintainers; [ michalrus moaxcp ];
  };
}
