set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

# Format every portable project file.
[default]
all:
    treefmt --no-cache

# Format all native source files, including C++ and CMake.
native: cpp cmake

# Format all C and C++ source and header files.
cpp:
    treefmt --no-cache -f cpp

# Format all CMake source files.
cmake:
    treefmt --no-cache -f cmake

# Format all Python files through uv-managed Ruff.
py:
    treefmt --no-cache -f python

# Format all miscellaneous portable files.
misc:
    treefmt --no-cache -f just,misc
