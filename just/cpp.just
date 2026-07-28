set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

default-preset := "quality"

# Native package checks used by continuous integration.
mod ci 'cpp/ci.just'

# Configure the native build.
[arg("fresh", long="fresh", value="true")]
configure preset=default-preset fresh="false":
    cmake --preset {{ preset }} {{ if fresh == "true" { "--fresh" } else { "" } }}

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

# Freshly configure, build, verify public headers, and test the native project.
check preset=default-preset: (configure preset "true") (build preset) (verify-headers preset) (test preset)
