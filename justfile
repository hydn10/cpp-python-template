set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# List the available developer workflows.
help:
    @just --list

# Use the native debug preset for the current supported platform by default.
default-cpp-preset := if os() == "windows" { "dev-x64-win-debug" } else { "dev-linux-debug" }

# Configure the C++ build (usage: just cpp-configure [preset]).
cpp-configure preset=default-cpp-preset:
    cmake --preset {{preset}}

# Build the configured C++ tree (usage: just cpp-build [preset]).
cpp-build preset=default-cpp-preset:
    cmake --build --preset {{preset}}

# Run native tests from the configured C++ tree (usage: just cpp-test [preset]).
cpp-test preset=default-cpp-preset:
    ctest --preset {{preset}}

# Configure, build, and test C++ with a CMake preset.
cpp-check preset=default-cpp-preset: (cpp-configure preset) (cpp-build preset) (cpp-test preset)

# Synchronize the locked Python environment.
py-sync:
    uv sync --locked

# Force a rebuild and reinstall of the native Python extension.
py-rebuild:
    uv sync --locked --reinstall-package mylib-tools

# Run the plotting CLI (usage: just plot --save path).
plot *args:
    uv run --locked mylib-plot {{args}}

# Run the CSV dump CLI (usage: just dump --points 5 --output path).
dump *args:
    uv run --locked mylib-dump {{args}}

# Run the native checks and synchronize the locked Python environment.
check preset=default-cpp-preset: (cpp-check preset) py-sync
