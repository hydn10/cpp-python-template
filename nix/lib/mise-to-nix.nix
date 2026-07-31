let
  fail = message: throw "mise-to-nix: ${message}";

  all = predicate: values:
    builtins.foldl' (result: value: result && predicate value) true values;

  unique = values:
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

  describeNames = names: builtins.concatStringsSep ", " names;

  normalizeConfiguredValue = name: value:
    let
      valueType = builtins.typeOf value;

      makeVersions = versions: options:
        if versions == [ ] then
          fail "tool '${name}' must configure at least one version"
        else if !all builtins.isString versions then
          fail "tool '${name}' has a version list containing a non-string value"
        else
          map
            (requestedVersion: {
              inherit name requestedVersion options;
              configValue = value;
            })
            versions;
    in
      if builtins.isString value then
        makeVersions [ value ] { }
      else if builtins.isList value then
        makeVersions value { }
      else if builtins.isAttrs value then
        if !builtins.hasAttr "version" value then
          fail "tool '${name}' uses an attribute set without a 'version' field"
        else
          let
            version = value.version;
            options = builtins.removeAttrs value [ "version" ];
          in
            if builtins.isString version then
              makeVersions [ version ] options
            else if builtins.isList version then
              makeVersions version options
            else
              fail "tool '${name}' has an attribute-set 'version' field of unsupported type '${builtins.typeOf version}' (expected a string or list of strings)"
      else
        fail "tool '${name}' has unsupported configuration type '${valueType}' (expected a string, list of strings, or an attribute set with 'version')";

  validateLockEntry = name: entry:
    if !builtins.isAttrs entry then
      fail "lock entry for tool '${name}' is not an attribute set"
    else if !builtins.hasAttr "version" entry then
      fail "lock entry for tool '${name}' has no 'version' field"
    else if !builtins.isString entry.version then
      fail "lock entry for tool '${name}' has a non-string 'version' field"
    else if builtins.hasAttr "backend" entry && !builtins.isString entry.backend then
      fail "lock entry for tool '${name}' has a non-string 'backend' field"
    else
      entry;

  groupLockEntries = name: entries:
    let
      grouped = builtins.foldl'
        (groups: unvalidatedEntry:
          let
            entry = validateLockEntry name unvalidatedEntry;
            version = entry.version;
            alreadyPresent = builtins.any
              (group: group.resolvedVersion == version)
              groups;
          in
            if alreadyPresent then
              map
                (group:
                  if group.resolvedVersion == version then
                    group // { rawLockEntries = group.rawLockEntries ++ [ entry ]; }
                  else
                    group)
                groups
            else
              groups ++ [{
                resolvedVersion = version;
                rawLockEntries = [ entry ];
              }])
        [ ]
        entries;

      finishGroup = group:
        let
          backends = unique (builtins.concatMap
            (entry:
              if builtins.hasAttr "backend" entry then [ entry.backend ] else [ ])
            group.rawLockEntries);
        in
          if builtins.length backends > 1 then
            fail "lock entries for tool '${name}' version '${group.resolvedVersion}' have contradictory backends: ${describeNames backends}"
          else
            group // {
              backend = if backends == [ ] then null else builtins.head backends;
              lockEntries = group.rawLockEntries;
            };
    in
      map finishGroup grouped;

  parseTools = { miseToml, miseLock }:
    let
      config = builtins.fromTOML (builtins.readFile miseToml);
      lock = builtins.fromTOML (builtins.readFile miseLock);

      configuredTools = config.tools or { };
      lockedTools = lock.tools or { };

      parseTool = name:
        let
          configuredVersions = normalizeConfiguredValue name configuredTools.${name};
          rawLockEntries =
            if !builtins.hasAttr name lockedTools then
              fail "configured tool '${name}' has no lockfile entry"
            else
              lockedTools.${name};
          lockGroups =
            if !builtins.isList rawLockEntries then
              fail "lockfile value for configured tool '${name}' is not a list"
            else if rawLockEntries == [ ] then
              fail "configured tool '${name}' has an empty lockfile entry list"
            else
              groupLockEntries name rawLockEntries;
          configuredCount = builtins.length configuredVersions;
          resolvedCount = builtins.length lockGroups;
        in
          if configuredCount != resolvedCount then
            fail "configured tool '${name}' requests ${toString configuredCount} version(s), but its lock entries contain ${toString resolvedCount} distinct resolved version(s)"
          else
            builtins.genList
              (index:
                builtins.elemAt configuredVersions index
                // builtins.elemAt lockGroups index)
              configuredCount;
    in
      if !builtins.isAttrs configuredTools then
        fail "the [tools] value in mise.toml is not an attribute set"
      else if !builtins.isAttrs lockedTools then
        fail "the [tools] value in mise.lock is not an attribute set"
      else
        builtins.concatMap parseTool (builtins.attrNames configuredTools);

  mapTools = { miseToml, miseLock }: mappings:
    let
      tools = parseTools { inherit miseToml miseLock; };
      configuredNames = unique (map (tool: tool.name) tools);
      mappingNames = builtins.attrNames mappings;
      missingMappings = builtins.filter
        (name: !builtins.hasAttr name mappings)
        configuredNames;
      extraMappings = builtins.filter
        (name: !(builtins.elem name configuredNames))
        mappingNames;
      nonFunctionMappings = builtins.filter
        (name: !builtins.isFunction mappings.${name})
        mappingNames;
      mappingMismatchMessages =
        (if missingMappings == [ ] then [ ] else
          [ "configured tools without mappings: ${describeNames missingMappings}" ])
        ++ (if extraMappings == [ ] then [ ] else
          [ "mapping keys without configured tools: ${describeNames extraMappings}" ]);

      mappedTools = map
        (tool:
          let
            package = mappings.${tool.name} tool;
          in
            tool // { inherit package; })
        tools;

      deduplicated = (builtins.foldl'
        (result: mappedTool:
          let
            identity = builtins.unsafeDiscardStringContext
              (builtins.toString mappedTool.package);
          in
            if builtins.hasAttr identity result.seen then
              result
            else
              {
                seen = result.seen // { "${identity}" = true; };
                values = result.values ++ [ mappedTool.package ];
              })
        { seen = { }; values = [ ]; }
        mappedTools).values;
    in
      if !builtins.isAttrs mappings then
        fail "mapTools expected 'mappings' to be an attribute set"
      else if mappingMismatchMessages != [ ] then
        fail (builtins.concatStringsSep "; " mappingMismatchMessages)
      else if nonFunctionMappings != [ ] then
        fail "mapping values that are not functions: ${describeNames nonFunctionMappings}"
      else
        {
          inherit tools mappedTools;
          packages = deduplicated;
        };
in
{
  inherit parseTools mapTools;
}
