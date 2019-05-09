{ stdenv
, fetchFromBitbucket
, llvm
, clang
, clang-unwrapped
, genie
, spirv-tools
, spirv-cross
, libc-hdrs
, clang-hdrs
}:
stdenv.mkDerivation rec {
  pname = "scopes";
  version = "unstable-2019-05-09";
  src = fetchFromBitbucket {
    owner = "duangle";
    repo = "scopes";
    rev = "3c5fd78";
    sha256 = "1im9lm0j4j4d797mwn97zfsfh91rls1arw52filzdi3wlq4zgxfi";
  };
  nativeBuildInputs = [ genie spirv-tools spirv-cross ];
  buildInputs = [ llvm clang-unwrapped ];
  postPatch = ''
    substituteInPlace genie.lua \
      --replace 'CLANG_PATH =' 'CLANG_PATH = "${clang}/bin:${llvm}/bin" -- ' \
      --replace '"SPIRV-Cross' '--"SPIRV-Cross' \
      --replace 'THISDIR .. "/SPIRV-Tools/build/source/opt/libSPIRV-Tools-opt.a"' '"-lSPIRV-Tools-opt"' \
      --replace 'THISDIR .. "/SPIRV-Tools/build/source/libSPIRV-Tools.a"' '"-lSPIRV-Tools -lspirv-cross-glsl -lspirv-cross-reflect -lspirv-cross-util -lspirv-cross-core"'
    substituteInPlace src/gen_spirv.cpp \
      --replace 'SPIRV-Cross' 'spirv_cross'
    substituteInPlace src/boot.cpp \
      --replace 'scopes_clang_include_dir = format' 'scopes_clang_include_dir = "${clang-hdrs}"; // format' \
      --replace 'scopes_include_dir = format' 'scopes_include_dir = "${libc-hdrs}"; // format'
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    sed -i "s^#include <limits.h>^#include <inttypes.h>\n#include <limits.h>^g" src/cache.cpp
    substituteInPlace src/cache.cpp --replace ', SCOPES_KEY16_FORMAT' ', "%016" PRIx64'
  '';
  configurePhase = ''
    genie gmake
  '';
  makefile = "Makefile";
  makeFlags = "-C build config=release";
  installPhase = ''
    install -d $out/bin
    install -d $out/lib
    cp bin/scopes $out/bin
    cp bin/lib* $out/lib
    cp -R lib/* $out/lib/
  '' + stdenv.lib.optionalString stdenv.isDarwin ''
    install_name_tool -change @executable_path/libscopesrt.dylib $out/lib/libscopesrt.dylib $out/bin/scopes
  '';
  doInstallCheck = false; # Uses ~/.cache
  installCheckPhase = ''
    $out/bin/scopes testing/check_all.sc
  '';
  enableParallelBuilding = true;

  meta = {
    description = "Retargetable programming language & infrastructure";
    homepage = https://bitbucket.org/duangle/scopes/wiki/Home;
    license = stdenv.lib.licenses.mit;
  };
}
