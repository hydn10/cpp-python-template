set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

default-preset := "quality"
repo-root := justfile_directory()

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

[private]
fresh-build preset: (configure preset "true")
    cmake --build --preset {{ preset }} --clean-first

[private]
validate-built preset: (verify-headers preset) (test preset)

# Freshly configure, cleanly build, validate public headers, and test the native project.
validate preset=default-preset: (fresh-build preset) (validate-built preset)

# Install one native build, then build and run a consumer of its CMake package.
[arg("preset", pattern="release|shared-release")]
check-installed preset="release":
    cmake --install "out/build/{{ preset }}"
    cmake -S tests/consumer-cmake -B "out/build/consumer-cmake/{{ preset }}" --fresh -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH={{ repo-root }}/out/install/{{ preset }}"
    cmake --build "out/build/consumer-cmake/{{ preset }}" --clean-first
    ctest --test-dir "out/build/consumer-cmake/{{ preset }}" --output-on-failure --no-tests=error
