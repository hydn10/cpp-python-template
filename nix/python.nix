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
  mylib = pkgs.callPackage ../default.nix { };

  overlay = workspace.mkPyprojectOverlay {
    sourcePreference = "wheel";
  };

  hacks = pkgs.callPackage pyproject-nix.build.hacks { };
  inherit (pkgs.callPackages pyproject-nix.build.util { }) mkApplication;

  pythonSet =
    (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope
      (pkgs.lib.composeManyExtensions [
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
              nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [
                pkgs.cmake
                pkgs.ninja
                python.pkgs.pybind11
              ];
              buildInputs = (old.buildInputs or [ ]) ++ (mylib.buildInputs or [ ]);
              env = (old.env or { }) // {
                CMAKE_GENERATOR = "Ninja";
                CMAKE_BUILD_TYPE = "Release";
              };
            });
          })
      ]);

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

in {
  inherit python pythonSet mylibApplication;

  shellPackages = [
    pkgs.uv
    python
  ];

  shellEnv =
    {
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
