{ lib, fetchPypi, buildPythonPackage, aiohttp, apispec_3, jinja2, webargs }:

buildPythonPackage rec {
  pname = "aiohttp-apispec";
  version = "2.2.1";

  src = fetchPypi {
    inherit version;
    pname = "aiohttp-apispec";
    sha256 = "0hhlmh3mc3xg68znsxyhypb5k12vg59yf72qkyw6ahg8zy3qfz2m";
    # sha256 = "1svh5h6agbxqk74f77xhmmgbgczs5ldvfaaby50mirh3aickwvfm";
  };

  propagatedBuildInputs = [ aiohttp apispec_3 jinja2 webargs ];

  doCheck = false;

  meta = {
    description = "Build and document REST APIs with aiohttp and apispec";
    license = lib.licenses.mit;
    homepage = "https://github.com/maximdanilchenko/aiohttp-apispec";
  };
}
