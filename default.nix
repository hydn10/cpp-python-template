{ lib
, stdenv
, python3
, cmake
, clang-tools
, buildTests ? false
, buildPython ? false
, buildExamples ? false
, enableClangTidy ? false
}:
let
  pname = "mylib";
  mylibJson = builtins.fromJSON (builtins.readFile ./mylib.json);

  version = mylibJson.version;

  mkCMakeFlag = opt: if opt then "ON" else "OFF";

  buildTestsFlag = mkCMakeFlag buildTests;
  buildPythonFlag = mkCMakeFlag buildPython;
  buildExamplesFlag = mkCMakeFlag buildExamples;
  enableClangTidyFlag = mkCMakeFlag enableClangTidy;

in
  stdenv.mkDerivation
  {
    inherit pname;

    name = "${pname}-${version}";
    inherit version;

    src = lib.cleanSource ./.;

    nativeBuildInputs = [ cmake ] ++ (if enableClangTidy then [ clang-tools ] else [ ]);

    cmakeFlags = [
      "-DBUILD_TESTING=${buildTestsFlag}"
      "-DBUILD_PYTHON=${buildPythonFlag}"
      "-DBUILD_EXAMPLES=${buildExamplesFlag}"
      "-DENABLE_CLANG_TIDY=${enableClangTidyFlag}"
    ];
  }