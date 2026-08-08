set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

import 'just/common.just'

# Source formatting.
mod format 'just/mods/format.just'

# Read-only formatting and linting checks.
mod check 'just/mods/check.just'

# Native CMake and CTest workflows.
mod cpp 'just/mods/cpp.just'

# Python environment and application workflows.
mod py 'just/mods/py.just'

# vcpkg dependency-provider maintenance.
mod vcpkg 'just/mods/vcpkg.just'

# Mise development-environment maintenance.
mod mise 'just/mods/mise.just'

# Disposable build state, environments, caches, and package outputs.
mod purge 'just/mods/purge.just'

# Local GitHub Actions workflow execution.
mod ci 'just/mods/ci.just'

# List all root and module recipes.
help:
    @just --list --list-submodules

# Run the complete local repository verification using one selected Python-quality tree.
verify preset=default-python-quality-preset: check::format::all (check::lint::all preset) (cpp::validate-built preset) (py::validate preset)
