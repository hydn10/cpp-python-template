{ pkgs }:
let
  adapter = import ./lib/mise-to-nix.nix;

  mappings = {
    act = _tool: pkgs.act;
    dprint = _tool: pkgs.dprint;
    gersemi = _tool: import ./pkgs/gersemi.nix { inherit pkgs; };
    just = _tool: pkgs.just;
    actionlint = _tool: pkgs.actionlint;
    shellcheck = _tool: pkgs.shellcheck;
  };
in
adapter.mapTools {
  miseToml = ../mise.toml;
  miseLock = ../mise.lock;
} mappings
