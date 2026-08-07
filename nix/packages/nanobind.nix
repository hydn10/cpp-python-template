{ pkgs, python }:

let
  cmakeSetupHook = pkgs.writeText "nanobind-cmake-setup-hook.sh" ''
    export nanobind_DIR="@out@/${python.sitePackages}/nanobind/cmake"
  '';
in
python.pkgs.nanobind.overridePythonAttrs (oldAttrs: {
  # The nixpkgs package installs nanobind's CMake configuration inside the
  # Python package. Expose that package-specific location to downstream CMake
  # builds whenever this nanobind derivation is activated.
  setupHooks = (oldAttrs.setupHooks or [ ]) ++ [ cmakeSetupHook ];

  # Fail while constructing the adapted package if the nixpkgs or upstream
  # installation layout changes, rather than leaving consumers with a broken
  # discovery variable.
  postFixup = (oldAttrs.postFixup or "") + ''
    test -f "$out/${python.sitePackages}/nanobind/cmake/nanobind-config.cmake"
  '';
})
