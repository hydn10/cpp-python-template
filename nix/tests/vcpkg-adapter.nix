{
  pkgs,
  python,
  dependencyCatalogue,
  vcpkgDependencies,
}:
let
  adapter = import ../lib/vcpkg-to-nix.nix;
  fixtures = ./fixtures;

  sharedPackage = pkgs.tree;
  mappings = {
    root-target = dependency:
      if
        !dependency.host
        && (
          (dependency.context.scope == "root" && dependency.requestedFeatures == [ ])
          || (
            dependency.context.feature == "python"
            && dependency.requestedFeatures == [ "python-context" ]
          )
          || (
            dependency.context.feature == "tools"
            && dependency.requestedFeatures == [ "tools-context" ]
          )
        )
      then
        pkgs.hello
      else
        throw "root-target did not receive normalized dependency metadata";
    root-host = dependency:
      if
        dependency.host
        && dependency.requestedFeatures == [ "tools" ]
        && dependency.defaultFeatures == false
        && dependency.versionAtLeast == "2.0"
      then
        pkgs.cowsay
      else
        throw "root-host did not receive normalized dependency metadata";
    feature-only = dependency:
      if
        dependency.requestedFeatures == [ "core" "extras" ]
        && dependency.features == [ "core" "extras" ]
        && dependency."default-features" == false
        && dependency."version>=" == "3.0"
      then
        pkgs.figlet
      else
        throw "feature-only did not receive normalized dependency metadata";
    feature-host = dependency:
      if dependency.host then pkgs.lolcat else throw "feature host metadata was lost";
    same-a = _dependency: sharedPackage;
    same-b = _dependency: sharedPackage;
  };

  mapped = adapter.mapDependencies {
    vcpkgJson = fixtures + "/vcpkg-valid.json";
  } mappings;

  one = name: builtins.head (builtins.filter
    (dependency: dependency.name == name)
    mapped.externalDependencies);

  fails = value:
    !(builtins.tryEval (builtins.deepSeq value true)).success;

  missingMapping = adapter.mapDependencies {
    vcpkgJson = fixtures + "/vcpkg-valid.json";
  } (builtins.removeAttrs mappings [ "feature-only" ]);

  staleMapping = adapter.mapDependencies {
    vcpkgJson = fixtures + "/vcpkg-valid.json";
  } (mappings // { stale = _dependency: pkgs.hello; });

  malformed = adapter.parseManifest {
    vcpkgJson = fixtures + "/vcpkg-malformed.json";
  };

  conditional = adapter.parseManifest {
    vcpkgJson = fixtures + "/vcpkg-platform.json";
  };

  pythonSelection = mapped.selectProjectFeatures [ "python" ];
  allFeatureSelection = mapped.selectProjectFeatures
    (builtins.attrNames mapped.projectFeatures);
  duplicateFeatureSelection = mapped.selectProjectFeatures [ "python" "python" ];
  unknownFeatureSelection = mapped.selectProjectFeatures [ "missing" ];

  repositoryFeatureSelection = vcpkgDependencies.selectProjectFeatures
    (builtins.attrNames vcpkgDependencies.projectFeatures);

  selfReference = builtins.head (builtins.filter
    (dependency: dependency.name == "fixture-project")
    mapped.projectFeatures.python.dependencies);

  packagePath = package: builtins.toString package;
  packagePaths = packages: map packagePath packages;

  assertions = [
    # Both declaration forms normalize to records, and an absent host flag is false.
    ((one "root-target").declaration == "root-target")
    (!(one "root-target").host)
    ((one "root-host").originalDeclaration.name == "root-host")

    # Root and every top-level project feature contribute dependencies.
    (map (dependency: dependency.name) mapped.externalRootDependencies
      == [ "root-target" "root-host" "same-a" ])
    (map (dependency: dependency.name) mapped.featureDependencies
      == [ "feature-only" "root-target" "feature-host" "same-b" ])
    (map (dependency: dependency.name) mapped.externalDependencies
      == [ "root-target" "root-host" "same-a" "feature-only" "feature-host" "same-b" ])

    # Root build and host dependencies are split before package realization.
    (map (dependency: dependency.name) mapped.rootTargetDependencies
      == [ "root-target" "same-a" ])
    (map (dependency: dependency.name) mapped.rootHostDependencies
      == [ "root-host" ])
    (packagePaths mapped.root.targetPackages
      == packagePaths [ pkgs.hello sharedPackage ])
    (packagePaths mapped.root.hostPackages == packagePaths [ pkgs.cowsay ])

    # Each project feature retains its own mapping context and package groups.
    (map (dependency: dependency.name) mapped.projectFeatures.python.externalDependencies
      == [ "feature-only" "root-target" ])
    (map (dependency: dependency.name) mapped.projectFeatures.tools.externalDependencies
      == [ "feature-host" "same-b" "root-target" ])
    (map (dependency: dependency.name) mapped.projectFeatures.python.targetDependencies
      == [ "feature-only" "root-target" ])
    (mapped.projectFeatures.python.hostDependencies == [ ])
    (map (dependency: dependency.name) mapped.projectFeatures.tools.targetDependencies
      == [ "same-b" "root-target" ])
    (map (dependency: dependency.name) mapped.projectFeatures.tools.hostDependencies
      == [ "feature-host" ])
    (packagePaths mapped.projectFeatures.python.packages
      == packagePaths [ pkgs.figlet pkgs.hello ])
    (packagePaths mapped.projectFeatures.python.additionalPackages
      == packagePaths [ pkgs.figlet ])
    (packagePaths mapped.projectFeatures.tools.packages
      == packagePaths [ sharedPackage pkgs.hello pkgs.lolcat ])
    (packagePaths mapped.projectFeatures.tools.additionalPackages
      == packagePaths [ pkgs.lolcat ])

    # Requested external features and other relevant metadata survive normalization.
    ((one "root-host").requestedFeatures == [ "tools" ])
    ((one "root-host").defaultFeatures == false)
    ((one "root-host").versionAtLeast == "2.0")
    ((one "feature-only").requestedFeatures == [ "core" "extras" ])

    # A self-feature reference remains inspectable but is not an external dependency.
    (selfReference.requestedFeatures == [ "internal-support" ])
    (!(builtins.elem "fixture-project" mapped.dependencyNames))

    # Duplicate dependency names and duplicate resulting store paths collapse.
    (builtins.length mapped.rootDeclarations == 4)
    (builtins.length mapped.rootDependencies == 3)
    (builtins.length mapped.root.mappedDependencies == 3)
    (builtins.length mapped.root.packages == 3)
    (builtins.length mapped.projectFeatures.python.mappedDependencies == 2)
    (builtins.length mapped.projectFeatures.tools.mappedDependencies == 3)
    (duplicateFeatureSelection.selectedNames == [ "python" ])
    (packagePaths pythonSelection.additionalPackages == packagePaths [ pkgs.figlet ])
    (packagePaths allFeatureSelection.additionalPackages
      == packagePaths [ pkgs.figlet pkgs.lolcat ])
    (packagePaths allFeatureSelection.effectiveTargetPackages
      == packagePaths [ pkgs.hello sharedPackage pkgs.figlet ])
    (packagePaths allFeatureSelection.effectiveHostPackages
      == packagePaths [ pkgs.cowsay pkgs.lolcat ])
    (builtins.length mapped.allPackages == 5)
    (builtins.length (builtins.filter
      (package: packagePath package == packagePath sharedPackage)
      mapped.allPackages) == 1)

    # Mapping mismatches, malformed declarations, and platform expressions fail.
    (fails missingMapping)
    (fails staleMapping)
    (fails malformed)
    (fails conditional)
    (fails unknownFeatureSelection)

    # The repository mappings are realized only through its shared catalogue.
    (packagePath dependencyCatalogue.eigen3 == packagePath pkgs.eigen)
    (packagePath dependencyCatalogue.pybind11 == packagePath python.pkgs.pybind11)
    (packagePaths vcpkgDependencies.root.targetPackages
      == packagePaths [ dependencyCatalogue.eigen3 ])
    (vcpkgDependencies.root.hostPackages == [ ])
    (packagePaths vcpkgDependencies.projectFeatures.python.additionalPackages
      == packagePaths [ dependencyCatalogue.pybind11 ])
    (packagePaths repositoryFeatureSelection.additionalPackages
      == packagePaths [ dependencyCatalogue.pybind11 ])
    (packagePaths vcpkgDependencies.allPackages
      == packagePaths [
        dependencyCatalogue.eigen3
        dependencyCatalogue.pybind11
      ])
  ];
in
assert builtins.all (value: value) assertions;
pkgs.runCommand "vcpkg-adapter-evaluation-tests" { } ''
  touch "$out"
''
