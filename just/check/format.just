set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

# Check every portable project file without changing it.
[default]
all:
    dprint check

# Check all native source files, including C++ and CMake.
native: cpp cmake

# Check all C and C++ source and header files through dprint and clang-format.
cpp:
    dprint check --config dprint-cpp.json

# Check all CMake source files through dprint and gersemi.
cmake:
    dprint check --config dprint-cmake.json

# Check all Python files through dprint and uv-managed Ruff.
py:
    dprint check --config dprint-python.json

# Check all miscellaneous portable files through dprint and Just.
misc:
    dprint check --config dprint-misc.json
