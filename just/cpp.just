set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

default-preset := "quality"
cpp-file-patterns := "'*.c' '*.cc' '*.cpp' '*.cxx' '*.h' '*.hh' '*.hpp' '*.hxx' '*.inl'"
repo-root := justfile_directory()

[private]
require-git:
    @git cat-file -e HEAD

# Format every tracked C and C++ source and header.
[unix]
format: require-git
    git ls-files -z -- {{ cpp-file-patterns }} | xargs -0 clang-format -i --

# Format every tracked C and C++ source and header.
[windows]
format: require-git
    clang-format -i -- @(git ls-files -- {{ cpp-file-patterns }})

# Check every tracked C and C++ source and header without changing it.
[unix]
format-check: require-git
    git ls-files -z -- {{ cpp-file-patterns }} | xargs -0 clang-format --dry-run --Werror --

# Check every tracked C and C++ source and header without changing it.
[windows]
format-check: require-git
    clang-format --dry-run --Werror -- @(git ls-files -- {{ cpp-file-patterns }})

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

# Run clang-tidy across every native target, including the Python binding.
lint: (fresh-build "python-quality")

# Freshly configure, cleanly build, validate public headers, and test the native project.
validate preset=default-preset: (fresh-build preset) (verify-headers preset) (test preset)

# Install one native build, then build and run a consumer of its CMake package.
[arg("preset", pattern="release|shared-release")]
check-installed preset="release":
    cmake --install "out/build/{{ preset }}"
    cmake -S tests/consumer-cmake -B "out/build/consumer-cmake/{{ preset }}" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH={{ repo-root }}/out/install/{{ preset }}"
    cmake --build "out/build/consumer-cmake/{{ preset }}"
    ctest --test-dir "out/build/consumer-cmake/{{ preset }}" --output-on-failure --no-tests=error
