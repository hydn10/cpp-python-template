{ lib
, stdenv
, python3
, cmake
, clang-tools
, eigen
, buildTests ? false
, buildPython ? false
, buildExamples ? false
, enableClangTidy ? false
}:
let
  pname = "mylib";
  vcpkgManifest = builtins.fromJSON (builtins.readFile ./vcpkg.json);

  version = vcpkgManifest.version;

  mkCMakeFlag = opt: if opt then "ON" else "OFF";

  buildTestsFlag = mkCMakeFlag buildTests;
  buildPythonFlag = mkCMakeFlag buildPython;
  buildExamplesFlag = mkCMakeFlag buildExamples;
in
  stdenv.mkDerivation
  {
    inherit pname;

    name = "${pname}-${version}";
    inherit version;

    src = lib.cleanSource ./.;

    nativeBuildInputs =
      [ cmake ]
      ++ (if enableClangTidy then [ clang-tools ] else [ ]);

    buildInputs = [ eigen ];

    cmakeFlags = [
      "-DMYLIB_BUILD_TESTING=${buildTestsFlag}"
      "-DMYLIB_BUILD_PYTHON=${buildPythonFlag}"
      "-DMYLIB_BUILD_EXAMPLES=${buildExamplesFlag}"
    ] ++ lib.optionals enableClangTidy [
      "-DCMAKE_CXX_CLANG_TIDY=clang-tidy;--warnings-as-errors=*"
      "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON"
    ] ++ lib.optionals buildPython [
      "-DCMAKE_POSITION_INDEPENDENT_CODE=ON"
    ];
  }
