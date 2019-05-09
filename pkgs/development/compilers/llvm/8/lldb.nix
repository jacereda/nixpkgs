{ stdenv
, fetch
, cmake
, zlib
, ncurses
, swig
, which
, libedit
, libxml2
, llvm
, clang-unwrapped
, python
, version
, darwin
}:

stdenv.mkDerivation {
  name = "lldb-${version}";

  src = fetch "lldb" "0wq3mi76fk86g2g2bcsr0yhagh1dlf2myk641ai58rc116gqp4a9";

  postPatch = ''
    # Fix up various paths that assume llvm and clang are installed in the same place
    sed -i 's,".*ClangConfig.cmake","${clang-unwrapped}/lib/cmake/clang/ClangConfig.cmake",' \
      cmake/modules/LLDBStandalone.cmake
    sed -i 's,".*tools/clang/include","${clang-unwrapped}/include",' \
      cmake/modules/LLDBStandalone.cmake
    sed -i 's,"$.LLVM_LIBRARY_DIR.",${llvm}/lib ${clang-unwrapped}/lib,' \
      cmake/modules/LLDBStandalone.cmake
    substituteInPlace tools/debugserver/source/CMakeLists.txt \
      --replace 'string(STRIP ${xcode_dev_dir} xcode_dev_dir)' 'set(xcode_dev_dir "/Applications/Xcode.app/Contents/Developer")'
    substituteInPlace source/Plugins/Process/Utility/StopInfoMachException.cpp \
      --replace 'RESOURCE_TYPE_IO' '4' \
      --replace 'EXC_RESOURCE_IO_DECODE_LIMIT(m_exc_code)' '(m_exc_code & 0x7fffULL)' \
      --replace 'EXC_RESOURCE_IO_OBSERVED(m_exc_subcode)' '(m_exc_subcode & 0x7fffULL)'
    substituteInPlace source/Plugins/Process/gdb-remote/GDBRemoteCommunication.cpp \
      --replace '#if defined(__APPLE__)' '#if 0'
    substituteInPlace source/Plugins/Process/gdb-remote/GDBRemoteCommunicationClient.cpp \
      --replace '#if defined(__APPLE__)' '#if 0'
    substituteInPlace tools/debugserver/source/RNBRemote.cpp \
      --replace 'APPLE' 'XAPPLE' \
      --replace '#include <compression.h>' '//#include <compression.h>' \
      --replace 'std::string compressed;' 'return orig; /*std::string compressed'\
      --replace '  return compressed;' '  return compressed;*/'
    substituteInPlace tools/debugserver/source/PThreadMutex.cpp \
      --replace '//===-- PThreadMutex.cpp' 'int __dummy__; //'
    substituteInPlace source/Host/common/GetOptInc.cpp \
      --replace '//===-- GetOptInc.cpp' 'int __dummy2__; //'
  '';

  nativeBuildInputs = [ cmake python which swig ];
  buildInputs = [ ncurses zlib libedit libxml2 llvm ]
    ++ stdenv.lib.optionals stdenv.isDarwin [ darwin.libobjc darwin.apple_sdk.libs.xpc darwin.apple_sdk.frameworks.Foundation darwin.bootstrap_cmds darwin.apple_sdk.frameworks.Carbon darwin.apple_sdk.frameworks.Cocoa darwin.cf-private ];

  CXXFLAGS = "-fno-rtti";
  hardeningDisable = [ "format" ];

  cmakeFlags = [
    "-DLLDB_CODESIGN_IDENTITY=" # codesigning makes nondeterministic
    "-DLLDB_INCLUDE_TESTS=no"
    "-DLLDB_USE_SYSTEM_DEBUGSERVER=ON"
  ];

  enableParallelBuilding = true;

  postInstall = ''
    mkdir -p $out/share/man/man1
    cp ../docs/lldb.1 $out/share/man/man1/

    install -D ../tools/lldb-vscode/package.json $out/share/vscode/extensions/llvm-org.lldb-vscode-0.1.0/package.json
    mkdir $out/share/vscode/extensions/llvm-org.lldb-vscode-0.1.0/bin
    ln -s $out/bin/lldb-vscode $out/share/vscode/extensions/llvm-org.lldb-vscode-0.1.0/bin
  '';

  meta = with stdenv.lib; {
    description = "A next-generation high-performance debugger";
    homepage    = http://llvm.org/;
    license     = licenses.ncsa;
    platforms   = platforms.all;
  };
}
