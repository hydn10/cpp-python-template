{
  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";

    vcpkg-nix-adapter = {
      url = "github:hydn10/vcpkg-nix-adapter/v0.2.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    mise-nix-adapter = {
      url = "github:hydn10/mise-nix-adapter/v0.1.0";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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

  outputs =
    {
      self,
      nixpkgs,
      vcpkg-nix-adapter,
      mise-nix-adapter,
      uv2nix,
      pyproject-nix,
      pyproject-build-systems,
    }:
    let
      supportedSystems = [ "x86_64-linux" ];

      mkSystemOutputs =
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};

          workspace = import ./nix {
            inherit
              pkgs
              uv2nix
              pyproject-nix
              pyproject-build-systems
              ;
            vcpkgAdapter = vcpkg-nix-adapter.lib;
            miseAdapter = mise-nix-adapter.lib;
          };

          devShellProjectFeatures = workspace.project.vcpkgDependencies.selectProjectFeatures (
            builtins.attrNames workspace.project.vcpkgDependencies.projectFeatures
          );

          pythonModules = workspace.python;
          mise = workspace.development.mise;

          projectName = workspace.project.cpp.package.pname;
          packageWithApps = workspace.project.cpp.packageWithApps;
          nativeSampleName = "${projectName}-sample";
          nativeSampleApp = {
            type = "app";
            program = "${packageWithApps}/bin/${nativeSampleName}";
            meta = {
              description = "Run the packaged native sample application for ${projectName}.";
            };
          };
          pythonScriptApps = builtins.listToAttrs (
            map (scriptName: {
              name = scriptName;
              value = {
                type = "app";
                program = "${pythonModules.application}/bin/${scriptName}";
                meta = {
                  description = "Run the packaged ${scriptName} Python application.";
                };
              };
            }) pythonModules.applicationScripts
          );
        in
        {
          packages = {
            default = workspace.project.cpp.package;
            "${projectName}" = workspace.project.cpp.package;
          };

          # Expose runnable apps
          apps = {
            default = nativeSampleApp;
            "${nativeSampleName}" = nativeSampleApp;
          }
          // pythonScriptApps;

          # Dev shell that inherits deps from the C++ package and adds the Python
          # development environment and provides common tools.
          devShells.default = pkgs.mkShell {
            inputsFrom = [ workspace.project.cpp.package ];

            packages =
              mise.packages
              # Root dependencies arrive through the native C++ package.
              # Every declared project feature is selected for the development shell,
              # which therefore only needs their packages that are additional to root.
              ++ devShellProjectFeatures.additionalPackages
              ++ pythonModules.shellPackages;

            env = pythonModules.shellEnv;
          };

          # Canonical formatter for the optional Nix integration.
          formatter = pkgs.nixfmt-tree;

          # Build every native category, verify public headers, and let the CMake
          # check phase run the registered native tests.
          checks = {
            cpp-quality = workspace.project.cpp.qualityCheck;

            python-apps = pythonModules.application;

            cmake-python-extension = workspace.project.cpp.pythonExtension;

            # Use the formatter's own check derivation so `nix fmt` and
            # `nix flake check` share both traversal and formatting policy.
            nix-format = self.formatter.${system}.check self;
          };
        };

      perSystem = nixpkgs.lib.genAttrs supportedSystems mkSystemOutputs;
    in
    {
      packages = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.packages) perSystem;
      apps = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.apps) perSystem;
      devShells = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.devShells) perSystem;
      formatter = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.formatter) perSystem;
      checks = nixpkgs.lib.mapAttrs (_: systemOutputs: systemOutputs.checks) perSystem;
    };
}
