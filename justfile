set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Source formatting and read-only quality checks.
mod format 'just/format.just'
mod check 'just/check.just'

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

# Run the complete local repository verification.
verify: check::format::all check::lint::all (cpp::validate "python-quality") py::validate
