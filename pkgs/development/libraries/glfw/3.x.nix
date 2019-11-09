{ stdenv, lib, fetchFromGitHub, cmake
, x11Support? (!stdenv.isDarwin), libGL, libXrandr, libXinerama, libXcursor, libX11, libXi, libXext
, Cocoa, Kernel, fixDarwinDylibNames
}:

stdenv.mkDerivation rec {
  version = "3.3";
  pname = "glfw";

  src = fetchFromGitHub {
    owner = "glfw";
    repo = "GLFW";
    rev = version;
    sha256 = "1f1hqpqffzg46z33ybs2c3akmkly7b3qmgp5byk50nvad6g2pm4p";
  };

  enableParallelBuilding = true;

  propagatedBuildInputs = lib.optional x11Support libGL;

  nativeBuildInputs = [ cmake ];

  buildInputs = lib.optionals x11Support [
    libX11 libXrandr libXinerama libXcursor libXi libXext
  ] ++ lib.optionals stdenv.isDarwin [
    Cocoa Kernel fixDarwinDylibNames
  ];
    ++ lib.optionals stdenv.isDarwin [ Cocoa Kernel fixDarwinDylibNames ];

  cmakeFlags = [ "-DBUILD_SHARED_LIBS=ON" ];

  preConfigure  = lib.optional x11Support ''
    substituteInPlace src/glx_context.c --replace "libGL.so.1" "${lib.getLib libGL}/lib/libGL.so.1"
  '';

  meta = with stdenv.lib; {
    description = "Multi-platform library for creating OpenGL contexts and managing input, including keyboard, mouse, joystick and time";
    homepage = https://www.glfw.org/;
    license = licenses.zlib;
    maintainers = with maintainers; [ marcweber twey ];
    platforms = platforms.unix;
  };
}
