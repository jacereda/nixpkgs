{ stdenv
, fetchurl
#, llvm_10
, libffi
}:
stdenv.mkDerivation rec {
  name = "copper";
  version = "4.4";
  src = fetchurl {
    url = "https://tibleiz.net/download/copper-${version}-src.tar.gz";
    sha256 = "1nf0bw143rjhd019yms3k6k531rahl8anidwh6bif0gm7cngfwfw";
  };
  buildInputs = [
#    llvm_10
    libffi
  ];
  postPatch = ''
  substituteInPlace Makefile --replace "-s scripts/" "scripts/"
  patchShebangs .
  '';
  buildPhase = ''
  make BACKEND=elf64 boot-elf64
  make BACKEND=elf64 COPPER=stage3/copper-elf64 copper-elf64
#  make BACKEND=llvm COPPER=stage3/copper-elf64 copper-llvm
#  make BACKEND=c COPPER=stage3/copper-elf64 copper-c
  '';
  installPhase = ''
  make BACKEND=elf64 install prefix=$out
#  make BACKEND=c install prefix=$out
#  make BACKEND=llvm install prefix=$out
  '';
  meta = with stdenv.lib; {
    description = "Simple imperative language, statically typed with type inference and genericity.";
    homepage = "https://tibleiz.net/copper/";
    license = licenses.bsd2;
    platforms = platforms.x86_64;
  };
}
