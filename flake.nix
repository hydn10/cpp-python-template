{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

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
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      cpp = import ./nix/cpp.nix { inherit pkgs; };

      pythonModules = import ./nix/python.nix {
        inherit pkgs uv2nix pyproject-nix pyproject-build-systems;
        python = pkgs.python3;
      };

      mylibWithApps = cpp.mylibWithApps;
      mylibWithTestsAndChecks = cpp.mylibWithTestsAndChecks;
    in {
      packages.${system} = {
        default = cpp.mylib;
        mylib = cpp.mylib;
        mylib-apps = mylibWithApps;
        python-apps = pythonModules.mylibApps;
        python-app = pythonModules.mylibApps;
      };

      # Expose runnable apps
      apps.${system} = {
        # First-party C++ application installed by CMake when applications are ON
        mylib-sample = {
          type = "app";
          program = "${mylibWithApps}/bin/mylib-sample";
          meta = {
            description = "Run the packaged native sample application for mylib.";
          };
        };
        # Python CLI from [project.scripts]
        mylib-plot = {
          type = "app";
          program = "${pythonModules.mylibApps}/bin/mylib-plot";
          meta = {
            description = "Run the packaged plotting CLI for the mylib template.";
          };
        };
        mylib-dump = {
          type = "app";
          program = "${pythonModules.mylibApps}/bin/mylib-dump";
          meta = {
            description = "Run the packaged CSV dump CLI for the mylib template.";
          };
        };
      };

      # Dev shell that inherits deps from both packages and also provides common tools
      devShells.${system}.default = pkgs.mkShell {
        # Pull C++ build deps; include Python env explicitly
        inputsFrom = [ cpp.mylib ];
        packages =
          [
            pkgs.llvmPackages_22.clang-tools
            pkgs.cmake
            pkgs.just
            pkgs.ninja
            pkgs.pkg-config
          ]
          ++ pythonModules.shellPackages;
        env = pythonModules.shellEnv;
        shellHook = ''
          echo "Dev shell ready"
          echo "- Workflows: run 'just help' to list the optional developer commands"
          echo "- C++: cmake + ninja available; presets write under out/build"
          echo "- Python: run 'uv sync --locked' to create/update .venv"
        '';
      };

      # Build every native category, verify public headers, and let the CMake
      # check phase run the registered native tests.
      checks.${system}.default = mylibWithTestsAndChecks.overrideAttrs (oldAttrs: {
        doCheck = true;
        preCheck = (oldAttrs.preCheck or "") + ''
          cmake --build . --target all_verify_interface_header_sets
        '';
      });
    };
}
