{ lib
, buildPythonPackage
, fetchPypi
, pyyaml
, prance
, marshmallow
, pytestCheckHook
, mock
, openapi-spec-validator
}:

buildPythonPackage rec {
  pname = "apispec";
  version = "3.3.2";

  src = fetchPypi {
    inherit pname version;
    sha256 = "1bdi81mq7z0s7qz86ln5aa2fzmg6nl8dn69an0qy0hg5f5dvsgnj";
  };

  checkInputs = [
    pyyaml
    prance
    openapi-spec-validator
    marshmallow
    mock
    pytestCheckHook
  ];

  meta = with lib; {
    description = "A pluggable API specification generator. Currently supports the OpenAPI Specification (f.k.a. the Swagger specification";
    homepage = "https://github.com/marshmallow-code/apispec";
    license = licenses.mit;
    maintainers = [ maintainers.costrouc ];
  };
}
