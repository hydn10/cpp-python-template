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

# Delete disposable local build state, environments, caches, and package outputs.
# Unlike `git clean`, this intentionally preserves ignored user configuration.
purge-all: purge-out
    cmake -E remove_directory ".venv"
    cmake -E remove_directory "venv"
    cmake -E remove_directory "build"
    cmake -E remove_directory "_skbuild"
    cmake -E remove_directory "dist"
    cmake -E remove_directory ".eggs"
    cmake -E remove_directory "pip-wheel-metadata"
    cmake -E remove_directory "CMakeFiles"
    cmake -E remove_directory ".pytest_cache"
    cmake -E remove_directory ".mypy_cache"
    cmake -E remove_directory ".ruff_cache"
    cmake -E remove_directory ".hypothesis"
    cmake -E remove_directory ".nox"
    cmake -E remove_directory ".tox"
    cmake -E remove_directory "htmlcov"
    cmake -E rm -f "CMakeCache.txt" ".coverage" "coverage.xml"
    Get-ChildItem -LiteralPath "apps", "cmake", "examples", "just", "lib", "nix", "python", "tests", "tools" -Directory -Recurse -Force -ErrorAction SilentlyContinue | Where-Object { $_.Name -in @("__pycache__", ".pytest_cache", ".mypy_cache", ".ruff_cache", ".hypothesis", "htmlcov") -or $_.Name -like "*.egg-info" } | Sort-Object -Property FullName -Descending | Remove-Item -Recurse -Force

default-cpp-preset := "quality"

# Run the native and Python developer checks.
check preset=default-cpp-preset: (cpp::check preset) py::check
