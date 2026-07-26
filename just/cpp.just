set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

default-preset := "quality"

# Native package checks used by continuous integration.
mod ci 'cpp/ci.just'

# Configure the native build.
configure preset=default-preset:
    cmake --preset {{ preset }}

# Build the configured native tree.
build preset=default-preset:
    cmake --build --preset {{ preset }}

# Clean built artifacts while preserving the configured native tree.
clean preset=default-preset:
    cmake --build --preset {{ preset }} --target clean

# Run tests from the configured native tree.
test preset=default-preset:
    ctest --preset {{ preset }}

# Verify that every public header can be included on its own.
verify-headers preset=default-preset:
    cmake --build --preset {{ preset }} --target all_verify_interface_header_sets

# Configure, build, verify public headers, and test the native project.
check preset=default-preset: (configure preset) (build preset) (verify-headers preset) (test preset)

# Remove one native build, install, and consumer tree.
rm preset=default-preset:
    cmake -E remove_directory "out/build/{{ preset }}"
    cmake -E remove_directory "out/install/{{ preset }}"
    cmake -E remove_directory "out/build/consumer-cmake/{{ preset }}"
