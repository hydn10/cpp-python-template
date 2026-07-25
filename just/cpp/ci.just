set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

default-preset := "release"
repo-root := justfile_directory()

# Install one native build and verify that its CMake package can be consumed.
check-installed preset=default-preset:
    cmake --install "out/build/{{ preset }}"
    cmake -S tests/consumer-cmake -B "out/build/consumer-cmake/{{ preset }}" -G Ninja -DCMAKE_BUILD_TYPE=Release "-DCMAKE_PREFIX_PATH={{ repo-root }}/out/install/{{ preset }}"
    cmake --build "out/build/consumer-cmake/{{ preset }}"
