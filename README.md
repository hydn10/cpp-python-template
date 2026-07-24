# mylib — Minimal C++ library with Python apps

This is a minimal example of a C++ library that is consumable from both C++ and Python. It uses modern CMake for the C++ project, a `vcpkg.json` manifest for C++ dependencies, pybind11 + scikit-build-core for the Python extension, and `uv` for Python environment management.

The C++ library stays Python-agnostic. It exposes a scalar helper and a more realistic data-generation function, while using Eigen internally to evaluate batches of sample points without exposing Eigen in the public API:

```cpp
double mylib::compute_value(double x);  // returns x*x + 1.0
std::vector<double> mylib::compute_values(double xmin, double xmax, std::size_t point_count);
```

Python here is still an application wrapper only. The internal extension is not intended as a public API; use the provided console scripts such as `mylib-plot` and `mylib-dump`.

The Python extension has one supported user-facing build path:

```text
uv
    -> scikit-build-core
        -> CMake
            -> pybind11 extension
                -> mylib
```

Ordinary CMake workflows build and test the native project only.

## Layout

- `lib/include/mylib/mylib.hpp` — public C++ header
- `lib/src/mylib.cpp` — C++ library implementation
- `examples/cpp_example.cpp` — tiny C++ app using the library
- `lib/src/bindings/python/module.cpp` — pybind11 module definition
- `python/src/mylib_tools/` — Python tool package, including the private extension at `_core`
- `CMakeLists.txt` — modern CMake project (installs C++ library + headers)
- `pyproject.toml` — scikit-build-core configuration for Python packaging

## Prereqs

- CMake >= 3.26
- C++23-capable compiler to build this repo's examples/tests
- C++17 is sufficient for downstream consumers of the installed `mylib` library target
- LLVM/clang-tidy 22 when static analysis is enabled
- [vcpkg](https://learn.microsoft.com/vcpkg/) with `VCPKG_ROOT` set when configuring outside Nix; the presets use it to provide the repo's manifest dependencies (currently `Eigen3`)
- Python 3.9+ and [uv](https://docs.astral.sh/uv/)

Outside Nix, the presets in `CMakePresets.json` route CMake through the vcpkg toolchain via `VCPKG_ROOT`, so the existing configure/build/test/workflow presets will pick up manifest dependencies automatically. If you run `cmake -S` manually instead of using a preset, pass the toolchain file explicitly:

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
  -DCMAKE_BUILD_TYPE=Release
```

## Build and run the C++ example

With development workflow presets:

```bash
cmake --workflow --preset dev-linux-debug-all
cmake --workflow --preset dev-linux-release-all
```

```powershell
cmake --workflow --preset dev-x64-win-debug-all
cmake --workflow --preset dev-x64-win-release-all
```

Single-config generators (Linux/macOS, Ninja, Unix Makefiles):

```bash
cmake -S . -B build \
  -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" \
  -DCMAKE_BUILD_TYPE=Release \
  -DMYLIB_BUILD_EXAMPLES=ON \
  -DMYLIB_BUILD_TESTING=OFF
cmake --build build
./build/examples/mylib-cpp-example
```

Multi-config generators (Visual Studio on Windows):

```powershell
cmake -S . -B build `
  -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" `
  -DMYLIB_BUILD_EXAMPLES=ON `
  -DMYLIB_BUILD_TESTING=OFF
cmake --build build --config Release
./build/examples/Release/mylib-cpp-example.exe
```

## Testing

- With CMake workflow presets:
  - Linux dev: `cmake --workflow --preset dev-linux-debug-all` or `cmake --workflow --preset dev-linux-release-all`
  - Linux: `cmake --workflow --preset ci-linux-all`
  - Windows dev: `cmake --workflow --preset dev-x64-win-debug-all` or `cmake --workflow --preset dev-x64-win-release-all`
  - Windows: `cmake --workflow --preset ci-windows-all`
- Just run tests via test presets:
  - Linux dev: `ctest --preset dev-linux-debug` or `ctest --preset dev-linux-release`
  - Linux: `ctest --preset ci-linux`
  - Windows dev: `ctest --preset dev-x64-win-debug -C Debug` or `ctest --preset dev-x64-win-release -C Release`
  - Windows: `ctest --preset ci-windows -C Release`

## Static Analysis (clang-tidy 22)

- LLVM 22 is required; configuration lives in `.clang-tidy` (tweak checks as needed).
- Run automatically during build by setting the standard CMake launcher variable:
  - Linux/macOS (Ninja/Makefiles):
    - `cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*' -DCMAKE_BUILD_TYPE=Debug`
    - `cmake --build build`
  - Windows (MSVC generator):
    - `cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*;--extra-arg=/EHsc'`
    - `cmake --build build --config Debug`
- Alternatively, run manually using compile commands:
  - `cmake -S . -B build -DCMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake" -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
  - `clang-tidy -p build lib/src/mylib.cpp examples/cpp_example.cpp`
  - Or `run-clang-tidy` if available.

## Nix (flake)

This repo includes a Nix flake targeting `x86_64-linux`.

- Build the C++ library (default package):
  - `nix build` → result is the installed library in `result/`
- Run the C++ example app:
  - `nix run .#mylib-example`
- Run the Python plotting app:
  - `nix run .#mylib-plot`
- Run the Python CSV dump app:
  - `nix run .#mylib-dump`
- Build the packaged Python apps environment:
  - `nix build .#python-apps`
- Enter a development shell with C++ and Python tools + deps available:
  - `nix develop`

Notes:

- The Python apps are built using uv2nix from `uv.lock` and `pyproject.toml`.
- The dev shell is uv-first: it provides the C++ toolchain, LLVM 22 tools, `uv`, and a pinned Nix Python interpreter, but it does not put the packaged Python apps environment on `PATH`. Inside `nix develop`, use `uv sync` to create/update `.venv` and `uv run ...` to execute project Python commands. The shell also exposes Nix-provided `tkinter` plus the X11/Wayland client libraries so uv-managed `matplotlib` can open interactive windows on Nix.
- If you want to pin a different Python (e.g. 3.12), adjust the `python = pkgs.python3;` line in `flake.nix` to `python = pkgs.python312;`.

## Python apps with UV (locked env)

This repo treats Python as a small set of console apps built on top of a shared internal extension. `uv sync --locked` is the supported extension build workflow: uv manages the environment and invokes scikit-build-core for the editable install.

```bash
# Create or refresh the lockfile when dependencies change
uv lock

# Create/sync the project environment from the lockfile
uv sync --locked

# Run the plotting demo
uv run --locked mylib-plot

# Save a plot instead of opening a window
uv run --locked mylib-plot --xmin -10 --xmax 10 --points 401 --save plot.png

# Dump sampled values as CSV
uv run --locked mylib-dump --points 5

# Write sampled values to a CSV file
uv run --locked mylib-dump --points 5 --output values.csv

# Internal import for debugging only
uv run --locked python -c "import mylib_tools._core as m; print(m.compute_values(-1.0, 1.0, 3))"
```

Notes:

- `uv sync` installs the project in editable mode, so there is no separate `uv pip install -e .` step.
- After C++ source changes, run `uv sync` again to rebuild the extension in the project environment.
- The Python build requires `pybind11` and will be provided automatically from `pyproject.toml`.
- Outside Nix, Python packaging builds also need Eigen to be discoverable by CMake; exporting `CMAKE_TOOLCHAIN_FILE="$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"` before `uv sync` is the simplest way to match the preset-based C++ builds.
- The project version used by the C++ build and Python distribution metadata is read from `vcpkg.json`.
- The console app runtime deps (`numpy`, `matplotlib`) are listed under `[project.dependencies]` and locked via `uv.lock`.

## Using the C++ library from another CMake project

After installing this project (`cmake --install build --config Release`), you can

```
find_package(mylib CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE mylib::mylib)
```
