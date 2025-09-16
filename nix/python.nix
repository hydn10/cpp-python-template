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

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope
      (pkgs.lib.composeManyExtensions [
        pyproject-build-systems.overlays.default
        overlay
        (final: prev: {
          "mylib-apps" = prev."mylib-apps".overrideAttrs (old: {
            nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
              pkgs.cmake
              pkgs.ninja
              pkgs.python3Packages.pybind11
            ];
            env = (old.env or { }) // {
              CMAKE_GENERATOR = "Ninja";
              CMAKE_ARGS = "-DBUILD_EXAMPLES=OFF";
              CMAKE_BUILD_TYPE = "Release";
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
  };
}

