{ lib, fetchPypi, buildPythonPackage, marshmallow }:

buildPythonPackage rec {
  pname = "webargs";
  version = "5.5.3";

  src = fetchPypi {
    inherit version;
    pname = "webargs";
    sha256 = "16pjzc265yx579ijz5scffyfd1vsmi87fdcgnzaj2by6w2i445l7";
  };

  propagatedBuildInputs = [ marshmallow ];

  doCheck = false;

  meta = {
    description = "Library for parsing and validating HTTP request objects";
    license = lib.licenses.mit;
    homepage = "https://github.com/marshmallow-code/webargs";
  };
}
