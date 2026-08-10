{
  pkgs,
  vcpkgDependencies,
  pythonFeature,
}:
let
  package = pkgs.callPackage ../packages/cpp-library.nix {
    targetBuildInputs = vcpkgDependencies.root.targetPackages;
    hostBuildInputs = vcpkgDependencies.root.hostPackages;
  };

  pythonExtension = package.override {
    buildPython = true;
    targetBuildInputs = pythonFeature.selection.effectiveTargetPackages;
    hostBuildInputs = pythonFeature.selection.effectiveHostPackages;
    pythonForHost = pythonFeature.python.package;
    pythonForBuild = pythonFeature.buildPython.package;
  };

  packageWithApps = package.override {
    buildApps = true;
  };

  qualityCheck =
    (packageWithApps.override {
      buildExamples = true;
      buildTests = true;
    }).overrideAttrs
      (oldAttrs: {
        nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
          pkgs.llvmPackages_22.clang-tools
        ];
        cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
          "-DCMAKE_CXX_CLANG_TIDY=clang-tidy;--warnings-as-errors=*"
          "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
        ];
        doCheck = true;
        preCheck = (oldAttrs.preCheck or "") + ''
          cmake --build . --target all_verify_interface_header_sets
        '';
      });
in
{
  inherit
    package
    packageWithApps
    pythonExtension
    qualityCheck
    ;
}
