set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Source formatting and read-only quality checks.
mod format 'just/format.just'
mod check 'just/check.just'

# Native CMake and CTest workflows.
mod cpp 'just/cpp.just'

# Python environment and application workflows.
mod py 'just/py.just'

# Disposable build state, environments, caches, and package outputs.
mod purge 'just/purge.just'

# Local GitHub Actions workflow execution.
mod ci 'just/ci.just'

# List all root and module recipes.
help:
    @just --list --list-submodules

# Run the complete local repository verification.
# The C++ linter supplies the fresh python-quality build consumed by validate-built.
verify: check::format::all check::lint::all (cpp::validate-built "python-quality") py::validate
