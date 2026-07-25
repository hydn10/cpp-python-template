set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

default-preset := "debug"

# Configure the native build.
configure preset=default-preset:
    cmake --preset {{ preset }}

# Build the configured native tree.
build preset=default-preset:
    cmake --build --preset {{ preset }}

# Run tests from the configured native tree.
test preset=default-preset:
    ctest --preset {{ preset }}

# Configure, build, and test the native project.
check preset=default-preset: (configure preset) (build preset) (test preset)

# Remove one native build and install tree.
clean preset=default-preset:
    cmake -E remove_directory "out/build/{{ preset }}"
    cmake -E remove_directory "out/install/{{ preset }}"
