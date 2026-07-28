set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Native CMake and CTest workflows.
mod cpp 'just/cpp.just'

# Python environment and application workflows.
mod py 'just/py.just'

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

default-cpp-preset := "quality"

# Run the native and Python developer checks.
check preset=default-cpp-preset: (cpp::check preset) py::check
