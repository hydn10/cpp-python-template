{ lib, vcpkgDependencies }:
let
  pythonFeature =
    vcpkgDependencies.projectFeatures.python or (throw "vcpkg project feature 'python' is required");

  getTargetDependency =
    name:
    let
      dependency = lib.findFirst (
        candidate: candidate.name == name
      ) (throw "vcpkg project feature 'python' must depend on ${name}") pythonFeature.mappedDependencies;
    in
    if dependency.host then
      throw "${name} must be a target dependency of the vcpkg project feature 'python'"
    else
      dependency;
in
{
  feature = pythonFeature;
  selection = vcpkgDependencies.selectProjectFeatures [ "python" ];
  python = getTargetDependency "python3";
  nanobind = getTargetDependency "nanobind";
}
