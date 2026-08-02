{ pkgs }:
let
  ignorePython = pkgs.python3Packages.buildPythonPackage {
    pname = "ignore-python";
    version = "0.3.0";
    format = "wheel";
    src = pkgs.fetchurl {
      url = "https://files.pythonhosted.org/packages/40/6c/2f366ae7ac6ee490e620ff0e5d18191f9ae9bbec82ae0921861b4b219dba/ignore_python-0.3.0-cp314-cp314-manylinux_2_17_x86_64.manylinux2014_x86_64.whl";
      hash = "sha256-5i7jRXYnX748q6uZJv52fY3ZfwXFZnrPWFRBHoBwM3M=";
    };
  };

  dependencies = with pkgs.python3Packages; [
    ignorePython
    lark
    platformdirs
    pyyaml
    colorama
  ];
in
# Remove once nixpkgs catches up: 0.23.2 cannot parse @PACKAGE_INIT@.
pkgs.gersemi.overrideAttrs (_oldAttrs: {
  version = "0.25.4";
  src = pkgs.fetchPypi {
    pname = "gersemi";
    version = "0.25.4";
    hash = "sha256-g0to5mP3RtLAr1S9m9VzrgIwa3a+h6sYDFLAWhtAMgY=";
  };
  inherit dependencies;
  propagatedBuildInputs = dependencies;
})
