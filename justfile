set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]

# Native CMake and CTest workflows.
mod cpp 'just/cpp.just'

# Python environment and application workflows.
mod py 'just/py.just'

# List all root and module recipes.
help:
    @just --list --list-submodules

# Delete the entire out/ directory, including every build and generated artifact.
rm-out:
    cmake -E remove_directory "out"

default-cpp-preset := "debug"

# Verify both native and Python extension build paths.
check preset=default-cpp-preset: (cpp::check preset) py::ci::smoke
