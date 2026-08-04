{
  pkgs,
  adapter,
}:
let
  mappings = {
    act = _: pkgs.act;
    # Use default version once nixpkgs catches up: 0.23.2 cannot parse @PACKAGE_INIT@.
    gersemi = _: import ./pkgs/gersemi.nix { inherit pkgs; };
    just = _: pkgs.just;
    actionlint = _: pkgs.actionlint;
    oxfmt = _: pkgs.oxfmt;
    shellcheck = _: pkgs.shellcheck;
    treefmt = _: pkgs.treefmt;
  };
in
adapter.mapTools {
  miseToml = ../mise.toml;
  miseLock = ../mise.lock;
} mappings
