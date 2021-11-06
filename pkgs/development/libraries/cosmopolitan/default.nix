{ lib, gccStdenv, fetchFromGitHub, runCommand, cosmopolitan
, mode? ""
}:

gccStdenv.mkDerivation rec {
  pname = "cosmopolitan";
  version = "e5d1536";

  src = fetchFromGitHub {
    owner = "jart";
    repo = "cosmopolitan";
    rev = version;
    sha256 = "0hywamcnf7wzvm3nw025vvg0kig2v4k9far7lwd6ycalsdrxwg97";
  };

  postPatch = ''
    patchShebangs build/
    # rm -r third_party/gcc
    rm test/tool/build/lib/bsu_test.c # https://twitter.com/JustineTunney/status/1355321045037662212
    rm third_party/python/Lib/test/test_ioctl.py
    substituteInPlace third_party/python/python.mk --replace third_party/python/Lib/test/test_ioctl.py ""
    substituteInPlace libc/rand/randtest.c --replace mcount mcnt
    substituteInPlace third_party/python/Lib/test/test_fileio.py --replace testUnclosedFDOnException xtestUnclosedFDOnException
    substituteInPlace third_party/python/Python/random.c --replace '#if 1' '#if 0'
  	echo "o/${mode}/third_party/python/pythontester.com.dbg: QUOTA += -M512m" >> third_party/python/python.mk
  '';

  dontConfigure = true;
  dontFixup = true;
  enableParallelBuilding = true;

  preBuild = ''
    makeFlagsArray=(
      SHELL=/bin/sh
      AS=${gccStdenv.cc.targetPrefix}as
      CC=${gccStdenv.cc.targetPrefix}gcc
      GCC=${gccStdenv.cc.targetPrefix}gcc
      CXX=${gccStdenv.cc.targetPrefix}g++
      LD=${gccStdenv.cc.targetPrefix}ld
      OBJCOPY=${gccStdenv.cc.targetPrefix}objcopy
      "MKDIR=mkdir -p"
      OVERRIDE_CCFLAGS=-Wno-error=old-style-definition
      MODE=${mode}
      )
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p $out/{bin,lib,include}
    install o/cosmopolitan.h $out/include
    install o/cosmopolitan.a o/libc/crt/crt.o o/ape/ape.{o,lds} $out/lib
    for h in `find libc -name \*.h`
    do
        install -D $h $out/include/$h
    done
    for b in `find o/ -name \*.com.dbg`
    do
        cp $b $out/bin/`basename $b|head -c -5`
    done
    cat > $out/bin/cosmoc <<EOF
    #!${gccStdenv.shell}
    exec ${gccStdenv.cc}/bin/${gccStdenv.cc.targetPrefix}gcc \
      -Os -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone \
      -fno-omit-frame-pointer -pg -mnop-mcount \
      -fno-stack-protector \
      -I $out/include \
      -include $out/include/cosmopolitan.h \
      "\$@" \
      -Wl,--gc-sections -Wl,-z,max-page-size=0x1000 \
      -fuse-ld=bfd -Wl,-T,$out/lib/ape.lds \
      $out/lib/{crt.o,ape.o,cosmopolitan.a}
    EOF
    chmod +x $out/bin/cosmoc
    runHook postInstall
  '';

  passthru.tests = lib.optional (gccStdenv.buildPlatform == gccStdenv.hostPlatform) {
    hello = runCommand "hello-world" { } ''
      printf 'main() { printf("hello world\\n"); }\n' >hello.c
      ${gccStdenv.cc}/bin/${gccStdenv.cc.targetPrefix}gcc -g -O -static -nostdlib -nostdinc -fno-pie -no-pie -mno-red-zone -o hello.com.dbg hello.c \
        -fuse-ld=bfd -Wl,-T,${cosmopolitan}/lib/ape.lds \
        -I ${cosmopolitan}/include \
        -include ${cosmopolitan}/include/cosmopolitan.h \
        ${cosmopolitan}/lib/{crt.o,ape.o,cosmopolitan.a}
      ${gccStdenv.cc.bintools.bintools_bin}/bin/objcopy -S -O binary hello.com.dbg hello.com
      ./hello.com
      printf "test successful" > $out
    '';
    cosmoc = runCommand "cosmoc-hello" { } ''
      printf 'main() { printf("hello world\\n"); }\n' >hello.c
      ${cosmopolitan}/bin/cosmoc hello.c
      ./a.out
      printf "test successful" > $out
    '';
  };

  meta = with lib; {
    homepage = "https://justine.lol/cosmopolitan/";
    description = "Your build-once run-anywhere c library";
    platforms = platforms.x86_64;
    badPlatforms = platforms.darwin;
    license = licenses.isc;
    maintainers = with maintainers; [ lourkeur tomberek ];
  };
}
