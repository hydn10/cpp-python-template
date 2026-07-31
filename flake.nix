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
      supportedSystems = [ "x86_64-linux" ];

      mkSystemOutputs = system:
        let
          pkgs = import nixpkgs { inherit system; };
          python = pkgs.python3;

          dependencyCatalogue = {
            eigen3 = pkgs.eigen;
            pybind11 = python.pkgs.pybind11;
          };

          vcpkgDependencies = import ./nix/vcpkg-dependencies.nix {
            catalogue = dependencyCatalogue;
          };

          devShellProjectFeatures = vcpkgDependencies.selectProjectFeatures
            (builtins.attrNames vcpkgDependencies.projectFeatures);

          cpp = import ./nix/cpp.nix {
            inherit pkgs vcpkgDependencies;
          };

          pythonModules = import ./nix/python.nix {
            inherit
              pkgs
              python
              dependencyCatalogue
              vcpkgDependencies
              uv2nix
              pyproject-nix
              pyproject-build-systems
              ;
            cppPackage = cpp.mylib;
          };

          mise = import ./nix/mise.nix { inherit pkgs; };

          mylibWithApps = cpp.mylibWithApps;
          mylibWithTestsAndChecks = cpp.mylibWithTestsAndChecks;
        in {
          packages = {
            default = cpp.mylib;
            mylib = cpp.mylib;
            mylib-native-apps = mylibWithApps;
            python-apps = pythonModules.mylibApplication;
          };

          # Expose runnable apps
          apps = {
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
              program = "${pythonModules.mylibApplication}/bin/mylib-plot";
              meta = {
                description = "Run the packaged plotting CLI for the mylib template.";
              };
            };
            mylib-dump = {
              type = "app";
              program = "${pythonModules.mylibApplication}/bin/mylib-dump";
              meta = {
                description = "Run the packaged CSV dump CLI for the mylib template.";
              };
            };
          };

          # Dev shell that inherits deps from the C++ package and adds the Python
          # development environment and provides common tools.
          devShells.default = pkgs.mkShell {
            inputsFrom = [ cpp.mylib ];
            packages =
              [
                pkgs.llvmPackages_22.clang-tools
                pkgs.ninja
                pkgs.pkg-config
              ]
              ++ mise.packages
              # Root dependencies arrive through cpp.mylib. Every declared
              # project feature is selected for the development shell, which
              # therefore only needs their packages that are additional to root.
              ++ devShellProjectFeatures.additionalPackages
              ++ pythonModules.shellPackages;
            env = pythonModules.shellEnv;
          };

          # Build every native category, verify public headers, and let the CMake
          # check phase run the registered native tests.
          checks.default = mylibWithTestsAndChecks.overrideAttrs (oldAttrs: {
            doCheck = true;
            preCheck = (oldAttrs.preCheck or "") + ''
              cmake --build . --target all_verify_interface_header_sets
            '';
          });

          checks.mise-to-nix = import ./nix/tests/mise-adapter.nix { inherit pkgs; };
          checks.vcpkg-to-nix = import ./nix/tests/vcpkg-adapter.nix {
            inherit pkgs python dependencyCatalogue vcpkgDependencies;
          };
        };

      perSystem = nixpkgs.lib.genAttrs supportedSystems mkSystemOutputs;
    in {
      packages = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.packages) perSystem;
      apps = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.apps) perSystem;
      devShells = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.devShells) perSystem;
      checks = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.checks) perSystem;
    };
}
