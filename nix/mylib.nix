{
  lib,
  stdenv,
  cmake,
  targetBuildInputs,
  hostBuildInputs,
  buildTests ? false,
  buildApps ? false,
  buildExamples ? false,
}:
let
  pname = "mylib";
  projectRoot = ../.;
  vcpkgManifest = builtins.fromJSON (builtins.readFile (projectRoot + "/vcpkg.json"));

  version = vcpkgManifest.version;

  mkCMakeFlag = opt: if opt then "ON" else "OFF";

  buildTestsFlag = mkCMakeFlag buildTests;
  buildAppsFlag = mkCMakeFlag buildApps;
  buildExamplesFlag = mkCMakeFlag buildExamples;
in
stdenv.mkDerivation {
  inherit pname;

  name = "${pname}-${version}";
  inherit version;

  src = lib.cleanSource projectRoot;

  nativeBuildInputs = [ cmake ] ++ hostBuildInputs;

  buildInputs = targetBuildInputs;

  cmakeFlags = [
    "-DMYLIB_BUILD_TESTING=${buildTestsFlag}"
    "-DMYLIB_BUILD_APPS=${buildAppsFlag}"
    "-DMYLIB_BUILD_EXAMPLES=${buildExamplesFlag}"
  ];
}
