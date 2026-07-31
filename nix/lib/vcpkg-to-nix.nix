# A pure membership adapter: vcpkg declarations select caller-provided Nix
# packages, without reproducing vcpkg's resolver, versions, or feature semantics.
let
  fail = message: throw "vcpkg-to-nix: ${message}";

  all = predicate: values:
    builtins.foldl' (result: value: result && predicate value) true values;

  describeNames = names: builtins.concatStringsSep ", " names;

  uniqueByName = dependencies:
    (builtins.foldl'
      (result: dependency:
        if builtins.hasAttr dependency.name result.seen then
          result
        else
          {
            seen = result.seen // { "${dependency.name}" = true; };
            values = result.values ++ [ dependency ];
          })
      { seen = { }; values = [ ]; }
      dependencies).values;

  uniqueStrings = values:
    (builtins.foldl'
      (result: value:
        if builtins.hasAttr value result.seen then
          result
        else
          {
            seen = result.seen // { "${value}" = true; };
            values = result.values ++ [ value ];
          })
      { seen = { }; values = [ ]; }
      values).values;

  packageIdentity = package:
    builtins.unsafeDiscardStringContext (builtins.toString package);

  uniquePackages = packages:
    (builtins.foldl'
      (result: package:
        let
          identity = packageIdentity package;
        in
          if builtins.hasAttr identity result.seen then
            result
          else
            {
              seen = result.seen // { "${identity}" = true; };
              values = result.values ++ [ package ];
            })
      { seen = { }; values = [ ]; }
      packages).values;

  normalizeDependency = location: context: declaration:
    let
      declarationType = builtins.typeOf declaration;

      makeDependency = {
        name,
        host,
        requestedFeatures,
        defaultFeatures,
        versionAtLeast,
      }: {
        inherit
          name
          host
          requestedFeatures
          defaultFeatures
          versionAtLeast
          declaration
          context
          ;
        originalDeclaration = declaration;

        # Keep the vcpkg spellings available alongside convenient Nix names.
        features = requestedFeatures;
        "default-features" = defaultFeatures;
        "version>=" = versionAtLeast;
      };
    in
      if builtins.isString declaration then
        if declaration == "" then
          fail "${location} is an empty dependency name"
        else
          makeDependency {
            name = declaration;
            host = false;
            requestedFeatures = [ ];
            defaultFeatures = null;
            versionAtLeast = null;
          }
      else if builtins.isAttrs declaration then
        if builtins.hasAttr "platform" declaration then
          fail "${location} declares a dependency-level 'platform' condition; platform expressions are not supported"
        else if !builtins.hasAttr "name" declaration then
          fail "${location} is an object without a 'name' field"
        else if !builtins.isString declaration.name || declaration.name == "" then
          fail "${location} has a 'name' field that is not a non-empty string"
        else if builtins.hasAttr "host" declaration && !builtins.isBool declaration.host then
          fail "${location} has a non-boolean 'host' field"
        else if builtins.hasAttr "features" declaration && !builtins.isList declaration.features then
          fail "${location} has a 'features' field that is not a list"
        else if builtins.hasAttr "features" declaration && !all builtins.isString declaration.features then
          fail "${location} has a 'features' list containing a non-string value"
        else if builtins.hasAttr "default-features" declaration && !builtins.isBool declaration."default-features" then
          fail "${location} has a non-boolean 'default-features' field"
        else if builtins.hasAttr "version>=" declaration && !builtins.isString declaration."version>=" then
          fail "${location} has a non-string 'version>=' field"
        else
          makeDependency {
            name = declaration.name;
            host = declaration.host or false;
            requestedFeatures = declaration.features or [ ];
            defaultFeatures = declaration."default-features" or null;
            versionAtLeast = declaration."version>=" or null;
          }
      else
        fail "${location} has unsupported type '${declarationType}' (expected a string or an object containing 'name')";

  parseManifest = { vcpkgJson }:
    let
      manifest = builtins.fromJSON (builtins.readFile vcpkgJson);

      packageName =
        if !builtins.isAttrs manifest then
          fail "vcpkg.json does not contain a JSON object"
        else if !builtins.hasAttr "name" manifest then
          fail "vcpkg.json has no package 'name' field"
        else if !builtins.isString manifest.name || manifest.name == "" then
          fail "vcpkg.json has a package 'name' field that is not a non-empty string"
        else
          manifest.name;

      rawRootDependencies = manifest.dependencies or [ ];
      rawFeatures = manifest.features or { };

      rootDeclarations =
        if !builtins.isList rawRootDependencies then
          fail "the root 'dependencies' value is not a list"
        else
          builtins.genList
            (index:
              normalizeDependency
                "root dependency at index ${toString index}"
                { scope = "root"; feature = null; inherit index; }
                (builtins.elemAt rawRootDependencies index))
            (builtins.length rawRootDependencies);

      parseFeature = featureName: feature:
        let
          rawDependencies =
            if !builtins.isAttrs feature then
              fail "project feature '${featureName}' is not an object"
            else
              feature.dependencies or [ ];

          dependencies =
            if !builtins.isList rawDependencies then
              fail "project feature '${featureName}' has a 'dependencies' value that is not a list"
            else
              builtins.genList
                (index:
                  normalizeDependency
                    "dependency at index ${toString index} of project feature '${featureName}'"
                    { scope = "feature"; feature = featureName; inherit index; }
                    (builtins.elemAt rawDependencies index))
                (builtins.length rawDependencies);
        in
          feature // { inherit dependencies; };

      projectFeatures =
        if !builtins.isAttrs rawFeatures then
          fail "the top-level 'features' value is not an object"
        else
          builtins.mapAttrs parseFeature rawFeatures;

      isExternal = dependency: dependency.name != packageName;

      rootDependencies = uniqueByName rootDeclarations;
      externalRootDeclarations = builtins.filter isExternal rootDeclarations;
      externalRootDependencies = uniqueByName externalRootDeclarations;

      featureDeclarationsByFeature = builtins.mapAttrs
        (_featureName: feature: feature.dependencies)
        projectFeatures;
      externalFeatureDependenciesByFeature = builtins.mapAttrs
        (_featureName: dependencies:
          uniqueByName (builtins.filter isExternal dependencies))
        featureDeclarationsByFeature;
      featureDependencies = uniqueByName (builtins.concatMap
        (featureName: externalFeatureDependenciesByFeature.${featureName})
        (builtins.attrNames externalFeatureDependenciesByFeature));

      rootTargetDependencies = uniqueByName
        (builtins.filter (dependency: !dependency.host) externalRootDeclarations);
      rootHostDependencies = uniqueByName
        (builtins.filter (dependency: dependency.host) externalRootDeclarations);

      externalDependencies = uniqueByName
        (externalRootDependencies ++ featureDependencies);

      parsed = {
        inherit
          manifest
          packageName
          rootDeclarations
          rootDependencies
          externalRootDependencies
          projectFeatures
          featureDeclarationsByFeature
          externalFeatureDependenciesByFeature
          featureDependencies
          rootTargetDependencies
          rootHostDependencies
          externalDependencies
          ;
        dependencyNames = map (dependency: dependency.name) externalDependencies;
      };
    in
      builtins.deepSeq parsed parsed;

  mapDependencies = { vcpkgJson }: mappings:
    if !builtins.isAttrs mappings then
      fail "mapDependencies expected 'mappings' to be an attribute set"
    else
      let
        parsed = parseManifest { inherit vcpkgJson; };
        dependencyNames = parsed.dependencyNames;
        mappingNames = builtins.attrNames mappings;
        missingMappings = builtins.filter
          (name: !builtins.hasAttr name mappings)
          dependencyNames;
        staleMappings = builtins.filter
          (name: !(builtins.elem name dependencyNames))
          mappingNames;
        nonFunctionMappings = builtins.filter
          (name: !builtins.isFunction mappings.${name})
          mappingNames;
        mismatchMessages =
          (if missingMappings == [ ] then [ ] else
            [ "external dependencies without mappings: ${describeNames missingMappings}" ])
          ++ (if staleMappings == [ ] then [ ] else
            [ "mapping keys without external dependencies: ${describeNames staleMappings}" ]);

        mapDependency = dependency:
          dependency // { package = mappings.${dependency.name} dependency; };
        packagesFor = dependencies:
          uniquePackages (map
            (dependency: (mapDependency dependency).package)
            dependencies);

        mappedRootDependencies = map mapDependency parsed.externalRootDependencies;
        rootTargetPackages = packagesFor parsed.rootTargetDependencies;
        rootHostPackages = packagesFor parsed.rootHostDependencies;
        rootPackages = uniquePackages (rootTargetPackages ++ rootHostPackages);
        rootPackageIdentities = builtins.listToAttrs (map
          (package: {
            name = packageIdentity package;
            value = true;
          })
          rootPackages);

        packagesNotInRoot = packages: builtins.filter
          (package: !builtins.hasAttr (packageIdentity package) rootPackageIdentities)
          packages;

        realizeProjectFeature = featureName: feature:
          let
            externalDependencies = parsed.externalFeatureDependenciesByFeature.${featureName};
            selfDependencies = builtins.filter
              (dependency: dependency.name == parsed.packageName)
              feature.dependencies;
            targetDependencies = uniqueByName (builtins.filter
              (dependency: !dependency.host)
              externalDependencies);
            hostDependencies = uniqueByName (builtins.filter
              (dependency: dependency.host)
              externalDependencies);
            mappedDependencies = map mapDependency externalDependencies;
            targetPackages = packagesFor targetDependencies;
            hostPackages = packagesFor hostDependencies;
            packages = uniquePackages (targetPackages ++ hostPackages);
            additionalPackages = packagesNotInRoot packages;
          in
            feature // {
              inherit
                externalDependencies
                selfDependencies
                targetDependencies
                hostDependencies
                mappedDependencies
                targetPackages
                hostPackages
                packages
                additionalPackages
                ;
            };

        projectFeatures = builtins.mapAttrs realizeProjectFeature parsed.projectFeatures;

        selectProjectFeatures = featureNames:
          if !builtins.isList featureNames then
            fail "selectProjectFeatures expected a list of project feature names"
          else if !all builtins.isString featureNames then
            fail "selectProjectFeatures received a feature-name list containing a non-string value"
          else
            let
              selectedNames = uniqueStrings featureNames;
              unknownNames = builtins.filter
                (name: !builtins.hasAttr name projectFeatures)
                selectedNames;
              selectedFeatures = map (name: projectFeatures.${name}) selectedNames;
              selectedProjectFeatures = builtins.listToAttrs (map
                (name: {
                  inherit name;
                  value = projectFeatures.${name};
                })
                selectedNames);
              featureTargetPackages = uniquePackages (builtins.concatMap
                (feature: feature.targetPackages)
                selectedFeatures);
              featureHostPackages = uniquePackages (builtins.concatMap
                (feature: feature.hostPackages)
                selectedFeatures);
              featurePackages = uniquePackages
                (featureTargetPackages ++ featureHostPackages);
              additionalPackages = packagesNotInRoot featurePackages;
              effectiveTargetPackages = uniquePackages
                (rootTargetPackages ++ featureTargetPackages);
              effectiveHostPackages = uniquePackages
                (rootHostPackages ++ featureHostPackages);
              allPackages = uniquePackages (rootPackages ++ featurePackages);
            in
              if unknownNames != [ ] then
                fail "unknown project features selected: ${describeNames unknownNames}"
              else
                {
                  inherit
                    selectedNames
                    selectedProjectFeatures
                    featureTargetPackages
                    featureHostPackages
                    featurePackages
                    additionalPackages
                    effectiveTargetPackages
                    effectiveHostPackages
                    allPackages
                    ;
                };

        allProjectFeatureSelection = selectProjectFeatures
          (builtins.attrNames projectFeatures);

        root = {
          dependencies = parsed.externalRootDependencies;
          targetDependencies = parsed.rootTargetDependencies;
          hostDependencies = parsed.rootHostDependencies;
          mappedDependencies = mappedRootDependencies;
          targetPackages = rootTargetPackages;
          hostPackages = rootHostPackages;
          packages = rootPackages;
        };
      in
        if mismatchMessages != [ ] then
          fail (builtins.concatStringsSep "; " mismatchMessages)
        else if nonFunctionMappings != [ ] then
          fail "mapping values that are not functions: ${describeNames nonFunctionMappings}"
        else
          parsed // {
            inherit
              root
              projectFeatures
              selectProjectFeatures
              ;
            allPackages = allProjectFeatureSelection.allPackages;
          };
in
{
  inherit parseManifest mapDependencies;
}
