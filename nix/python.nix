{ pkgs
, python ? pkgs.python3
, uv2nix
, pyproject-nix
, pyproject-build-systems
}:
let
  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../.;
  };

  # Temporary shim until pyproject-build-systems adds native nanobind support.
  nanobindBuildSystemShim = final: prev: {
    nanobind = pkgs.lib.extendDerivation true {
      passthru = (python.pkgs.nanobind.passthru or { }) // {
        dependencies = { };
        optional-dependencies = { };
        dependency-groups = { };
      };
    } python.pkgs.nanobind;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope
      (pkgs.lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        nanobindBuildSystemShim
        overlay
        (final: prev: {
          "mylib-apps" = prev."mylib-apps".overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              pkgs.cmake
              pkgs.ninja
              final.nanobind
            ];
            env = (old.env or { }) // {
              CMAKE_GENERATOR = "Ninja";
              CMAKE_BUILD_TYPE = "Release";
              # nixpkgs installs nanobind's CMake package under site-packages.
              nanobind_DIR = "${final.nanobind}/${python.sitePackages}/nanobind/cmake";
            };
          });
        })
      ]);

  mylibApps = pythonSet.mkVirtualEnv "mylib-apps-env" workspace.deps.default;

in {
  inherit python pythonSet mylibApps;

  shellPackages = [
    pkgs.uv
    mylibApps
    python
  ];

  shellEnv = {
    UV_NO_SYNC = "1";
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON = python.interpreter;
    # Wheels installed by uv (for example NumPy) may still need these shared
    # libraries at runtime on Nix systems.
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
    ];
  };
}
