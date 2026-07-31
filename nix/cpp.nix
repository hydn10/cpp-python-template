{ pkgs, vcpkgDependencies }:
let
  mylib = pkgs.callPackage ./mylib.nix {
    targetBuildInputs = vcpkgDependencies.root.targetPackages;
    hostBuildInputs = vcpkgDependencies.root.hostPackages;
  };
  mylibWithApps = mylib.override {
    buildApps = true;
  };
  mylibWithTestsAndChecks =
    (mylibWithApps.override {
      buildExamples = true;
      buildTests = true;
    }).overrideAttrs (oldAttrs: {
      nativeBuildInputs = (oldAttrs.nativeBuildInputs or [ ]) ++ [
        pkgs.llvmPackages_22.clang-tools
      ];
      cmakeFlags = (oldAttrs.cmakeFlags or [ ]) ++ [
        "-DCMAKE_CXX_CLANG_TIDY=clang-tidy;--warnings-as-errors=*"
        "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
      ];
    });
in {
  inherit mylib mylibWithApps mylibWithTestsAndChecks;
}
