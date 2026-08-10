{
  lib,
  stdenv,
  cmake,
  ninja,
  targetBuildInputs,
  hostBuildInputs,
  pythonForBuild ? null,
  pythonForHost ? null,
  buildTests ? false,
  buildApps ? false,
  buildExamples ? false,
  buildPython ? false,
}:
let
  projectRoot = ../../.;
  vcpkgManifest = builtins.fromJSON (builtins.readFile (projectRoot + "/vcpkg.json"));

  projectName = vcpkgManifest.name;
  version = vcpkgManifest.version;
  pname = if buildPython then "${projectName}-python-extension" else projectName;

  mkCMakeFlag = opt: if opt then "ON" else "OFF";

  buildTestsFlag = mkCMakeFlag buildTests;
  buildAppsFlag = mkCMakeFlag buildApps;
  buildExamplesFlag = mkCMakeFlag buildExamples;
  buildPythonFlag = mkCMakeFlag buildPython;

  pythonCMakeFlags =
    if !buildPython then
      [ ]
    else
      [
        "-DPython_ROOT_DIR=${pythonForHost}"
        "-DPython_BUILD_EXECUTABLE=${pythonForBuild.interpreter}"
      ];
in
stdenv.mkDerivation (
  {
    inherit pname;

    name = "${pname}-${version}";
    inherit version;

    src = lib.cleanSource projectRoot;

    strictDeps = true;

    nativeBuildInputs = [
      cmake
    ]
    ++ hostBuildInputs
    ++ lib.optionals buildPython [
      ninja
      pythonForBuild
    ];

    buildInputs = targetBuildInputs;

    cmakeFlags = [
      "-DMYLIB_BUILD_TESTING=${buildTestsFlag}"
      "-DMYLIB_BUILD_APPS=${buildAppsFlag}"
      "-DMYLIB_BUILD_EXAMPLES=${buildExamplesFlag}"
      "-DMYLIB_BUILD_PYTHON=${buildPythonFlag}"
    ]
    ++ lib.optionals buildPython [ "-DCMAKE_POSITION_INDEPENDENT_CODE=ON" ]
    ++ pythonCMakeFlags;
  }
  // lib.optionalAttrs buildPython {
    cmakeGenerator = "Ninja";
  }
)
