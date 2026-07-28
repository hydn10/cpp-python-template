{ lib
, stdenv
, cmake
, eigen
, buildTests ? false
, buildApps ? false
, buildExamples ? false
}:
let
  pname = "mylib";
  vcpkgManifest = builtins.fromJSON (builtins.readFile ./vcpkg.json);

  version = vcpkgManifest.version;

  mkCMakeFlag = opt: if opt then "ON" else "OFF";

  buildTestsFlag = mkCMakeFlag buildTests;
  buildAppsFlag = mkCMakeFlag buildApps;
  buildExamplesFlag = mkCMakeFlag buildExamples;
in
  stdenv.mkDerivation
  {
    inherit pname;

    name = "${pname}-${version}";
    inherit version;

    src = lib.cleanSource ./.;

    nativeBuildInputs = [ cmake ];

    buildInputs = [ eigen ];

    cmakeFlags = [
      "-DMYLIB_BUILD_TESTING=${buildTestsFlag}"
      "-DMYLIB_BUILD_APPS=${buildAppsFlag}"
      "-DMYLIB_BUILD_EXAMPLES=${buildExamplesFlag}"
    ];
  }
