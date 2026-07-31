set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Native CMake and CTest workflows.
mod cpp 'just/cpp.just'

# Python environment and application workflows.
mod py 'just/py.just'

# Local GitHub Actions workflow execution.
mod ci 'just/ci.just'

# List all root and module recipes.
help:
    @just --list --list-submodules

# Delete the entire out/ directory, including every build and generated artifact.
purge-out:
    cmake -E remove_directory "out"

dry-run-help := "Show what would be removed without deleting anything"

# Delete disposable local state, environments and caches. Pass -d/--dry-run to preview.
[arg("dry_run", long="dry-run", short="d", value="true", help=dry-run-help)]
[unix]
purge-all dry_run="false":
    bash "tools/purge-all/purge-all.sh" {{ if dry_run == "true" { "--dry-run" } else { "" } }} "{{ justfile_directory() }}"

# Delete disposable local state, environments and caches. Pass -d/--dry-run to preview.
[arg("dry_run", long="dry-run", short="d", value="true", help=dry-run-help)]
[windows]
purge-all dry_run="false":
    & "tools/purge-all/purge-all.ps1" {{ if dry_run == "true" { "-DryRun" } else { "" } }} -RepositoryRoot "{{ justfile_directory() }}"

# Format every supported repository file.
format: cpp::format py::format format-misc

# Check formatting for every supported repository file without changing it.
format-check: cpp::format-check py::format-check format-check-misc

# Format Just recipes and dprint-managed miscellaneous files.
format-misc:
    just --fmt
    dprint fmt

# Check Just recipes and dprint-managed miscellaneous files without changing them.
format-check-misc:
    just --fmt --check
    dprint check

# Run all formatting and static-analysis checks.
quality: format-check py::lint cpp::lint

# Run the complete local repository verification.
verify: format-check py::lint (cpp::validate "python-quality") py::validate
