{ pkgs }:
let
  mylib = pkgs.callPackage ../default.nix { };
  mylibWithExamples = mylib.override {
    buildExamples = true;
  };
  mylibWithTestsAndChecks = mylibWithExamples.override {
    buildTests = true;
    enableClangTidy = true;
  };
in {
  inherit mylib mylibWithExamples mylibWithTestsAndChecks;
}

