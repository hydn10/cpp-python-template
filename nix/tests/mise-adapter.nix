{ pkgs }:
let
  adapter = import ../lib/mise-to-nix.nix;
  fixtures = ./fixtures;

  sharedPackage = pkgs.hello;
  mappings = {
    single = _tool: sharedPackage;
    options = _tool: pkgs.cowsay;
    multi = tool: if tool.resolvedVersion == "1.9.0" then pkgs.figlet else pkgs.lolcat;
    repeated = _tool: pkgs.tree;
    same-a = _tool: sharedPackage;
    same-b = _tool: sharedPackage;
  };
  mapped = adapter.mapTools {
    miseToml = fixtures + "/mise-valid.toml";
    miseLock = fixtures + "/mise-valid.lock";
  } mappings;
  tools = mapped.tools;

  byName = name: builtins.filter (tool: tool.name == name) tools;
  one = name: builtins.head (byName name);

  fails = value:
    !(builtins.tryEval (builtins.deepSeq value true)).success;

  missingMapping = adapter.mapTools {
    miseToml = fixtures + "/mise-valid.toml";
    miseLock = fixtures + "/mise-valid.lock";
  } (builtins.removeAttrs mappings [ "single" ]);

  extraMapping = adapter.mapTools {
    miseToml = fixtures + "/mise-valid.toml";
    miseLock = fixtures + "/mise-valid.lock";
  } (mappings // { stale = _tool: pkgs.hello; });

  missingLock = adapter.mapTools {
    miseToml = fixtures + "/mise-missing-lock.toml";
    miseLock = fixtures + "/mise-missing-lock.lock";
  } { missing = _tool: pkgs.hello; };

  assertions = [
    # The stale lock-only tool is ignored.
    (builtins.length tools == 7)
    (byName "stale" == [ ])

    # String and attribute-set declarations preserve their source information.
    ((one "single").requestedVersion == "latest")
    ((one "single").resolvedVersion == "1.2.3")
    ((one "options").requestedVersion == "2")
    ((one "options").options.channel == "stable")
    ((one "same-b").options.feature == "test")

    # Requested and resolved versions are paired in their respective order.
    (map (tool: tool.requestedVersion) (byName "multi") == [ "1" "2" ])
    (map (tool: tool.resolvedVersion) (byName "multi") == [ "1.9.0" "2.4.0" ])

    # Repeated artifact entries form one logical version and retain raw metadata.
    (builtins.length (byName "repeated") == 1)
    (builtins.length (one "repeated").rawLockEntries == 2)
    ((one "repeated").backend == "test:repeated")

    # Mapping mismatches and missing locks fail during evaluation.
    (fails missingMapping)
    (fails extraMapping)
    (fails missingLock)

    # Seven logical records map to five unique package store paths.
    (builtins.length mapped.mappedTools == 7)
    (builtins.length mapped.packages == 5)
    (builtins.length (builtins.filter
      (package: builtins.toString package == builtins.toString sharedPackage)
      mapped.packages) == 1)
  ];
in
assert builtins.all (value: value) assertions;
pkgs.runCommand "mise-adapter-evaluation-tests" { } ''
  touch "$out"
''
