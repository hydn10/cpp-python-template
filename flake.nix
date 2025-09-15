{
  inputs = {
    # Track nixpkgs; you can update with `nix flake update` later.
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    # Optional: included for future uv-based workflows; devShell exposes `uv`.
    uv2nix.url = "github:pyproject-nix/uv2nix";
  };

  outputs = { self, nixpkgs, uv2nix }:
    let
      system = "x86_64-linux"; # scope limited as requested
      pkgs = import nixpkgs { inherit system; };

      # Use the default Python from nixpkgs so it tracks updates; easy to change.
      python = pkgs.python3;

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

      # Python CLI app built via PEP 517 using scikit-build-core
      mylibApps = python.pkgs.buildPythonApplication rec {
        pname = "mylib-apps";
        version = "0.1.0";
        pyproject = true;
        src = ./.;

        # Build-time tools and PEP 517 backend deps (match pyproject [build-system])
        nativeBuildInputs = [
          pkgs.cmake
          pkgs.ninja
          python.pkgs.scikit-build-core
          python.pkgs.pybind11
        ];

        # Runtime Python deps
        propagatedBuildInputs = [
          python.pkgs.numpy
          python.pkgs.matplotlib
        ];

        # Avoid building extra artifacts here
        env.CMAKE_BUILD_TYPE = "Release";
        env.CMAKE_ARGS = "-DBUILD_EXAMPLES=OFF";

        # No tests defined here
        doCheck = false;
      };
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
        # Pull buildInputs/propagatedBuildInputs from the packages automatically
        inputsFrom = [ mylib mylibApps ];

        nativeBuildInputs = [
          pkgs.cmake
          pkgs.ninja
          pkgs.pkg-config
          pkgs.uv  # convenient uv tool in the shell
        ];

        # Make the chosen Python and pip available conveniently
        buildInputs = [ python python.pkgs.pip ];

        # Helpful environment hints
        shellHook = ''
          echo "Dev shell ready"
          echo "- C++: cmake + ninja available; build dir suggestion: out/build"
          echo "- Python: ${python.interpreter} with numpy/matplotlib; uv available"
        '';
      };
    };
}

