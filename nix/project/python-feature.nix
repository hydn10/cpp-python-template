{ lib, vcpkgDependencies }:
let
  pythonFeature =
    vcpkgDependencies.projectFeatures.python or (throw "vcpkg project feature 'python' is required");

  getDependency =
    name: host:
    let
      dependency =
        lib.findFirst (candidate: candidate.name == name && candidate.host == host)
          (throw "vcpkg project feature 'python' must depend on ${name} with host=${toString host}")
          pythonFeature.mappedDependencies;
    in
    dependency;
in
{
  feature = pythonFeature;
  selection = vcpkgDependencies.selectProjectFeatures [ "python" ];
  python = getDependency "python3" false;
  buildPython = getDependency "python3" true;
  nanobind = getDependency "nanobind" false;
}
