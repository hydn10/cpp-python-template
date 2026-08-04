# Just's cross-platform executable lookup returns a list; list values and the
# helper function are currently unstable. Keep both local to formatting orchestration.
set unstable
set lists

nixfmt-available := which("nixfmt") != []
nixfmt-skip-command := "echo 'Skipped Nix formatting: nixfmt is unavailable; enter nix develop to provide it.'"
nixfmt-required-message := "nixfmt is unavailable; enter `nix develop` to use the canonical Nix development environment."

nixfmt_command(action, required) := if nixfmt-available { "dprint " + action + " --config dprint-nix.json" } else if required { error(nixfmt-required-message) } else { nixfmt-skip-command }
