{
  pkgs,
  python,
  cppPackage,
  vcpkgDependencies,
  uv2nix,
  pyproject-nix,
  pyproject-build-systems,
}:
let
  pythonFeature =
    vcpkgDependencies.projectFeatures.python or (throw "vcpkg project feature 'python' is required");

  nanobindDependency =
    let
      dependency = pkgs.lib.findFirst (
        candidate: candidate.name == "nanobind"
      ) (throw "vcpkg project feature 'python' must depend on nanobind") pythonFeature.mappedDependencies;
    in
    if dependency.host then
      throw "nanobind must be a target dependency of the vcpkg project feature 'python'"
    else
      dependency;

  workspace = uv2nix.lib.workspace.loadWorkspace {
    workspaceRoot = ../.;
  };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  hacks = pkgs.callPackage pyproject-nix.build.hacks { };
  inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;

  pythonSet = (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope (
    pkgs.lib.composeManyExtensions [
      pyproject-build-systems.overlays.wheel
      overlay
      (_final: prev: {
        matplotlib = hacks.nixpkgsPrebuilt {
          from = python.pkgs.matplotlib;
          prev = prev.matplotlib;
        };

        tkinter = hacks.nixpkgsPrebuilt {
          from = python.pkgs.tkinter;
        };

        "mylib-tools" = prev."mylib-tools".overrideAttrs (old: {
          nativeBuildInputs =
            (old.nativeBuildInputs or [ ])
            ++ [
              pkgs.cmake
              pkgs.ninja
              # Use the same mapped nanobind package as the vcpkg Python
              # feature, including its Nix-specific CMake setup hook.
              nanobindDependency.package
            ]
            ++ vcpkgDependencies.root.hostPackages;
          buildInputs = (old.buildInputs or [ ]) ++ (cppPackage.buildInputs or [ ]);
          env = (old.env or { }) // {
            CMAKE_GENERATOR = "Ninja";
          };
        });
      })
    ]
  );

  mylibVenv = pythonSet.mkVirtualEnv "mylib-tools-env" (
    workspace.deps.default
    // {
      tkinter = [ ];
    }
  );

  mylibApplication = mkApplication {
    venv = mylibVenv;
    package = pythonSet."mylib-tools";
  };

in
{
  inherit python pythonSet mylibApplication;

  shellPackages = [
    pkgs.uv
    python
  ];

  shellEnv = {
    UV_PYTHON_DOWNLOADS = "never";
    UV_PYTHON = python.interpreter;
    # uv manages .venv in the dev shell, but Tk is still supplied by nixpkgs.
    PYTHONPATH = "${python.pkgs.tkinter}/${python.sitePackages}";
  }
  // pkgs.lib.optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
    # PyPI wheels used by uv need GUI/runtime libraries visible on Nix.
    LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
      pkgs.stdenv.cc.cc.lib
      pkgs.zlib
      pkgs.libx11
      pkgs.wayland
    ];
  };
}
