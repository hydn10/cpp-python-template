{ pkgs, adapter }:
let
  # Raw provider packages are intentionally scoped to mapping construction.
  # Project consumers use only the mapped records returned below.
  pythonProvider = pkgs.python3;

  nanobindProvider = import ../packages/nanobind.nix {
    inherit pkgs;
    python = pythonProvider;
  };

  vcpkgDependencies =
    adapter.mapDependencies
      {
        vcpkgJson = ../../vcpkg.json;
      }
      {
        eigen3 = _: pkgs.eigen;
        python3 =
          dependency: if dependency.host then pythonProvider.pythonOnBuildForHost else pythonProvider;
        nanobind = _: nanobindProvider;
      };

  pythonFeature = import ./python-feature.nix {
    inherit (pkgs) lib;
    inherit vcpkgDependencies;
  };

  cpp = import ./cpp.nix {
    inherit pkgs vcpkgDependencies pythonFeature;
  };
in
{
  inherit cpp pythonFeature vcpkgDependencies;
}
