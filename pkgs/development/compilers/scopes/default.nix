{stdenv
, fetchFromBitbucket
, llvm_8
, clang
, clang-unwrapped
, genie
, spirv-tools
, spirv-cross
, libc
}:

stdenv.mkDerivation rec {
  pname = "scopes";
  version = "0.16-pre";
  src = fetchFromBitbucket {
    owner = "duangle";
    repo = "scopes";
#    rev = "release-${version}";
    rev = "288446ecfbca";
#    sha256 = "0qvp6wd6gn6rszh25x0fl233y47c0903xz02qk8lncq27qnxl03h";
    sha256 = "1rhag029fd90x3d19l2kfy69vcnfl5q4s0j764pshpnkkwd43xwv";
  };
  nativeBuildInputs = [ genie spirv-tools spirv-cross ];
  buildInputs = [ llvm_8 clang-unwrapped ];
  postPatch = ''
    substituteInPlace genie.lua \
      --replace 'CLANG_PATH =' 'CLANG_PATH = "${clang}/bin:${llvm_8}/bin" -- ' \
      --replace '"SPIRV-Cross' '--"SPIRV-Cross' \
      --replace 'THISDIR .. "/SPIRV-Tools/build/source/opt/libSPIRV-Tools-opt.a"' '"-lSPIRV-Tools-opt"' \
      --replace 'THISDIR .. "/SPIRV-Tools/build/source/libSPIRV-Tools.a"' '"-lSPIRV-Tools -lspirv-cross-glsl -lspirv-cross-reflect -lspirv-cross-util -lspirv-cross-core"'
    substituteInPlace src/gen_spirv.cpp \
      --replace 'SPIRV-Cross' 'spirv_cross'
    substituteInPlace src/boot.cpp \
      --replace 'scopes_clang_include_dir = format' 'scopes_clang_include_dir = "${clang-unwrapped}/include"; // format' \
      --replace 'scopes_include_dir = format' 'scopes_include_dir = "${libc}/include"; // format'
    substituteInPlace src/cache.cpp \
      --replace '16lx' '16llx'
  '';
  configurePhase = ''
    genie gmake
  '';
  buildPhase = ''
  make -C build config=release -j$NIX_BUILD_CORES
  '';
  installPhase = ''
    install -d $out/bin
    install -d $out/lib
    cp bin/scopes $out/bin
    cp bin/libscopesrt.dylib $out/lib
    install_name_tool -change @executable_path/libscopesrt.dylib $out/lib/libscopesrt.dylib $out/bin/scopes
    cp -R lib/* $out/lib/
  '';
  enableParallelBuilding = true;

  meta = {
    description = "Retargetable programming language & infrastructure";
    homepage = https://bitbucket.org/duangle/scopes/wiki/Home;
    license = stdenv.lib.licenses.mit;
  };
}
