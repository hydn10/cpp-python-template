set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

import '../format-nix.just'

# Format every supported repository file.
[default]
all:
    dprint fmt
    @{{ nixfmt_command("fmt", []) }}

# Format all native source files, including C++ and CMake.
native: cpp cmake

# Format all C and C++ source and header files through dprint and clang-format.
cpp:
    dprint fmt --config dprint-cpp.json

# Format all CMake source files through dprint and gersemi.
cmake:
    dprint fmt --config dprint-cmake.json

# Format all Python files through dprint and uv-managed Ruff.
py:
    dprint fmt --config dprint-python.json

# Format all miscellaneous repository files through dprint and Just.
misc:
    dprint fmt --config dprint-misc.json

# Format all Nix files through dprint and nixfmt (requires nixfmt).
nix:
    @{{ nixfmt_command("fmt", "true") }}
