set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Native CMake and CTest workflows.
mod cpp 'just/cpp.just'

# Python environment and application workflows.
mod py 'just/py.just'

# List all root and module recipes.
help:
    @just --list --list-submodules

default-cpp-preset := "debug"

# Verify both native and Python extension build paths.
check preset=default-cpp-preset:
    just cpp check {{ preset }}
    just py rebuild
