{
  pkgs,
  adapter,
}:
let
  mappings = {
    act = _: pkgs.act;
    clang-format = _: pkgs.llvmPackages_22.clang-tools;
    clang-tools = _: pkgs.llvmPackages_22.clang-tools;
    cmake = _: pkgs.cmake;
    # Use default version once nixpkgs catches up: 0.23.2 cannot parse @PACKAGE_INIT@.
    gersemi = _: import ../packages/gersemi.nix { inherit pkgs; };
    just = _: pkgs.just;
    ninja = _: pkgs.ninja;
    actionlint = _: pkgs.actionlint;
    oxfmt = _: pkgs.oxfmt;
    precious = _: pkgs.precious;
    shellcheck = _: pkgs.shellcheck;
    uv = _: pkgs.uv;
  };
in
# mapTools deliberately rejects both missing and extra mapping keys, so every
# tool declared in mise.toml must have an explicit Nix equivalent here.
adapter.mapTools {
  miseToml = ../../mise.toml;
  miseLock = ../../mise.lock;
} mappings
