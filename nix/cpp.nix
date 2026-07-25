{ pkgs }:
let
  mylib = pkgs.callPackage ../default.nix { };
  mylibWithApps = mylib.override {
    buildApps = true;
  };
  mylibWithTestsAndChecks = mylibWithApps.override {
    buildExamples = true;
    buildTests = true;
    enableClangTidy = true;
  };
in {
  inherit mylib mylibWithApps mylibWithTestsAndChecks;
}

