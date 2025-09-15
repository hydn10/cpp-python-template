{
  inputs = {
    # Track nixpkgs; you can update with `nix flake update` later.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    # Pyproject/nix builders and uv2nix for building from uv.lock
    pyproject-nix = {
      url = "github:pyproject-nix/pyproject.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    uv2nix = {
      url = "github:pyproject-nix/uv2nix";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    pyproject-build-systems = {
      url = "github:pyproject-nix/build-system-pkgs";
      inputs.pyproject-nix.follows = "pyproject-nix";
      inputs.uv2nix.follows = "uv2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    uv2nix,
    pyproject-nix,
    pyproject-build-systems,
  }:
    let
      system = "x86_64-linux"; # scope limited as requested
      pkgs = import nixpkgs { inherit system; };

      # Use the default Python from nixpkgs so it tracks updates; easy to change.
      python = pkgs.python3;

      # Load uv workspace from repo root (uses pyproject.toml + uv.lock)
      workspace = uv2nix.lib.workspace.loadWorkspace { workspaceRoot = ./.; };

      # Overlay mapping workspace packages to pyproject.nix builders
      overlay = workspace.mkPyprojectOverlay {
        # Prefer wheels for third-party packages; local packages still build from sources
        sourcePreference = "wheel";
      };

      # Compose a Python package set via pyproject.nix + uv2nix overlay + build-system fixups
      pythonSet =
        (pkgs.callPackage pyproject-nix.build.packages { inherit python; }).overrideScope
          (pkgs.lib.composeManyExtensions [
            pyproject-build-systems.overlays.default
            overlay
            # Ensure scikit-build-core can find CMake/Ninja when building the local package
            (final: prev: {
              "mylib-apps" = prev."mylib-apps".overrideAttrs (old: {
                nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgs.cmake pkgs.ninja ];
                # Keep examples off inside the Python wheel build
                env = (old.env or { }) // {
                  CMAKE_GENERATOR = "Ninja";
                  CMAKE_ARGS = "-DBUILD_EXAMPLES=OFF";
                  CMAKE_BUILD_TYPE = "Release";
                };
              });
            })
          ]);

      # C++ library package (default)
      mylib = pkgs.stdenv.mkDerivation {
        pname = "mylib";
        version = "0.1.0";
        src = ./.;

        nativeBuildInputs = [ pkgs.cmake ];
        # Build only the C++ parts for the default library package
        cmakeFlags = [
          "-DBUILD_PYTHON=OFF"
          "-DBUILD_EXAMPLES=ON"
        ];

        # Standard CMake phases (provided by cmake/ninja setup hooks)
        doCheck = false;
      };

      # Build virtualenvs from uv workspace deps
      mylibApps = pythonSet.mkVirtualEnv "mylib-apps-env" workspace.deps.default;
    in {
      packages.${system} = {
        default = mylib;
        mylib = mylib;
        python-app = mylibApps;
      };

      # Expose runnable apps
      apps.${system} = {
        # C++ example (installed into $out/bin by CMake when examples are ON)
        mylib-example = {
          type = "app";
          program = "${mylib}/bin/mylib_example";
        };
        # Python CLI from [project.scripts]
        mylib-plot = {
          type = "app";
          program = "${mylibApps}/bin/mylib-plot";
        };
      };

      # Dev shell that inherits deps from both packages and also provides common tools
      devShells.${system}.default = pkgs.mkShell {
        # Pull C++ build deps; include Python env explicitly
        inputsFrom = [ mylib ];
        packages = [
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.uv
          python
        ];
        env = {
          # Keep uv pure and use nixpkgs Python inside the shell
          UV_NO_SYNC = "1";
          UV_PYTHON_DOWNLOADS = "never";
          UV_PYTHON = python.interpreter;
        };
        shellHook = ''
          unset PYTHONPATH
          echo "Dev shell ready"
          echo "- C++: cmake + ninja available; build dir suggestion: out/build"
          echo "- Python venv from uv2nix on PATH; uv available"
        '';
      };
    };
}

