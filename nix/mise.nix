{
  pkgs,
  adapter,
}:
let
  mappings = {
    act = _: pkgs.act;
    dprint = _: pkgs.dprint;
    # Use default version once nixpkgs catches up: 0.23.2 cannot parse @PACKAGE_INIT@.
    gersemi = _: import ./pkgs/gersemi.nix { inherit pkgs; };
    just = _: pkgs.just;
    actionlint = _: pkgs.actionlint;
    shellcheck = _: pkgs.shellcheck;
  };
in
adapter.mapTools {
  miseToml = ../mise.toml;
  miseLock = ../mise.lock;
} mappings
