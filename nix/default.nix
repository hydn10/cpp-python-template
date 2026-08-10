{
  pkgs,
  vcpkgAdapter,
  miseAdapter,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
let
  # Parameterize project construction by the package set so one constructor
  # can instantiate native or cross package graphs.
  mkProject =
    projectPkgs:
    import ./project {
      pkgs = projectPkgs;
      adapter = vcpkgAdapter;
    };

  project = mkProject pkgs;

  python = import ./packages/python-apps.nix {
    inherit
      pkgs
      uv2nix
      pyproject-nix
      pyproject-build-systems
      ;
    inherit (project) vcpkgDependencies pythonFeature;
    cppPackage = project.cpp.package;
  };

  development = {
    mise = import ./development/mise.nix {
      inherit pkgs;
      adapter = miseAdapter;
    };
  };
in
{
  inherit
    development
    mkProject
    project
    python
    ;
}
