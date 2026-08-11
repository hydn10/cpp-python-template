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
    gersemi = _: pkgs.gersemi;
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
