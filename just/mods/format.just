set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

# Format every portable project file.
[default]
all:
    precious tidy --all

# Format all native source files, including C++ and CMake.
native: cpp cmake

# Format all C and C++ source and header files.
cpp:
    precious tidy --all --label cpp

# Format all CMake source files.
cmake:
    precious tidy --all --label cmake

# Format all Python files through uv-managed Ruff.
py:
    precious tidy --all --label py

# Format all miscellaneous portable files.
misc:
    precious tidy --all --label misc
