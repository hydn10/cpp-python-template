{
  pkgs,
  vcpkgDependencies,
  pythonFeature,
}:
let
  mylib = pkgs.callPackage ../packages/mylib.nix {
    targetBuildInputs = vcpkgDependencies.root.targetPackages;
    hostBuildInputs = vcpkgDependencies.root.hostPackages;
  };

  mylibPythonExtension = mylib.override {
    buildPython = true;
    targetBuildInputs = pythonFeature.selection.effectiveTargetPackages;
    hostBuildInputs = pythonFeature.selection.effectiveHostPackages;
    pythonForHost = pythonFeature.python.package;
    pythonForBuild = pythonFeature.buildPython.package;
  };

  mylibWithApps = mylib.override {
    buildApps = true;
  };

  mylibQualityCheck =
    (mylibWithApps.override {
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
    mylib
    mylibPythonExtension
    mylibWithApps
    mylibQualityCheck
    ;
}
