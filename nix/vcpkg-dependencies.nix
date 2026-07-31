{ catalogue }:
let
  adapter = import ./lib/vcpkg-to-nix.nix;

  mappings = {
    eigen3 = _dependency: catalogue.eigen3;
    pybind11 = _dependency: catalogue.pybind11;
  };
in
adapter.mapDependencies {
  vcpkgJson = ../vcpkg.json;
} mappings
