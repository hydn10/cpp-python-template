set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

# Check every portable project file without changing it.
[default]
all:
    precious lint --all

# Check all native source files, including C++ and CMake.
native: cpp cmake

# Check all C and C++ source and header files.
cpp:
    precious lint --all --label cpp

# Check all CMake source files.
cmake:
    precious lint --all --label cmake

# Check all Python files through uv-managed Ruff.
py:
    precious lint --all --label py

# Check all miscellaneous portable files.
misc:
    precious lint --all --label misc
