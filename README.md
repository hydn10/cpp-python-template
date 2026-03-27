# mylib — Minimal C++ library with Python apps

This is a minimal example of a C++ library that is consumable from both C++ and Python. It uses modern CMake for the C++ project, nanobind + scikit-build-core for the Python extension, and `uv` for Python environment management.

The C++ library stays Python-agnostic. It exposes a scalar helper and a more realistic data-generation function:

```cpp
double mylib::compute_value(double x);  // returns x*x + 1.0
std::vector<double> mylib::compute_values(double xmin, double xmax, std::size_t point_count);
```

Python here is still an application wrapper only. The internal extension is not intended as a public API; use the provided console scripts.

## Layout

- `include/mylib/mylib.hpp` — public C++ header
- `src/mylib.cpp` — C++ library implementation
- `examples/cpp_example.cpp` — tiny C++ app using the library
- `src/bindings/python/module.cpp` — nanobind module definition
- `python/mylib_apps/` — Python application package (console scripts), internal extension at `_core`
- `CMakeLists.txt` — modern CMake project (installs C++ library + headers)
- `pyproject.toml` — scikit-build-core configuration for Python packaging

## Prereqs

- CMake >= 3.25
- C++23-capable compiler to build this repo's examples/tests
- C++17 is sufficient for downstream consumers of the installed `mylib` library target
- Python 3.9+ and [uv](https://docs.astral.sh/uv/)

## Build and run the C++ example

Single-config generators (Linux/macOS, Ninja, Unix Makefiles):

```bash
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release -DMYLIB_BUILD_EXAMPLES=ON -DMYLIB_BUILD_TESTING=OFF
cmake --build build
./build/examples/mylib-cpp-example
```

Multi-config generators (Visual Studio on Windows):

```powershell
cmake -S . -B build -DMYLIB_BUILD_EXAMPLES=ON -DMYLIB_BUILD_TESTING=OFF
cmake --build build --config Release
./build/examples/Release/mylib-cpp-example.exe
```

## Testing

- With CMake workflow presets:
  - Linux: `cmake --workflow --preset ci-linux-all`
  - Windows: `cmake --workflow --preset ci-windows-all`
- Just run tests via test presets:
  - Linux: `ctest --preset ci-linux`
  - Windows: `ctest --preset ci-windows -C Release`

## Static Analysis (clang-tidy)

- Configuration lives in `.clang-tidy` (tweak checks as needed).
- Run automatically during build by setting the standard CMake launcher variable:
  - Linux/macOS (Ninja/Makefiles):
    - `cmake -S . -B build -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*' -DCMAKE_BUILD_TYPE=Debug`
    - `cmake --build build`
  - Windows (MSVC generator):
    - `cmake -S . -B build -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*;--extra-arg=/EHsc'`
    - `cmake --build build --config Debug`
- Alternatively, run manually using compile commands:
  - `cmake -S . -B build -DCMAKE_EXPORT_COMPILE_COMMANDS=ON`
  - `clang-tidy -p build src/mylib.cpp src/bindings/python/module.cpp examples/cpp_example.cpp`
  - Or `run-clang-tidy` if available.

## Nix (flake)

This repo includes a Nix flake targeting `x86_64-linux`.

- Build the C++ library (default package):
  - `nix build` → result is the installed library in `result/`
- Run the C++ example app:
  - `nix run .#mylib-example`
- Run the Python plotting app (console script):
  - `nix run .#mylib-plot`
- Enter a development shell with C++ and Python tools + deps available:
  - `nix develop`

Notes:

- The Python app is built using uv2nix from `uv.lock` and `pyproject.toml`.
- The dev shell inherits the C++ package deps and provides a uv2nix-built virtualenv for runtime dependencies (no Python test tooling), plus `cmake`, `ninja`, `pkg-config`, and `uv`. The Python interpreter used is `pkgs.python3` (nixpkgs’ default), so it will track nixpkgs updates.
- If you want to pin a different Python (e.g. 3.12), adjust the `python = pkgs.python3;` line in `flake.nix` to `python = pkgs.python312;`.
- When `buildPython = true`, the Nix derivation also passes `-DCMAKE_POSITION_INDEPENDENT_CODE=ON` so the static C++ library can be linked into the Python extension on platforms that require PIC.

## Python apps with UV (locked env)

This repo treats Python as an application wrapper for visualization. Let `uv` manage the environment and editable install.

```bash
# Create or refresh the lockfile when dependencies change
uv lock

# Create/sync the project environment from the lockfile
uv sync --frozen

# Run the plotting demo
uv run mylib-plot

# Save a plot instead of opening a window
uv run mylib-plot --xmin -10 --xmax 10 --points 401 --save plot.png

# Internal import for debugging only
uv run python -c "import mylib_apps._core as m; print(m.compute_values(-1.0, 1.0, 3))"
```

Notes:

- `uv sync` installs the project in editable mode, so there is no separate `uv pip install -e .` step.
- After C++ source changes, run `uv sync` again to rebuild the extension in the project environment.
- The Python build requires `nanobind` and will be provided automatically from `pyproject.toml`.
- The scikit-build frontend in `pyproject.toml` passes `-DMYLIB_BUILD_PYTHON=ON` and `-DCMAKE_POSITION_INDEPENDENT_CODE=ON` for Python packaging builds.
- For direct CMake builds, the Python extension is skipped unless you pass `-DMYLIB_BUILD_PYTHON=ON` and provide nanobind to CMake. On platforms that require PIC for shared modules, also pass `-DCMAKE_POSITION_INDEPENDENT_CODE=ON`.
- The application runtime deps (`numpy`, `matplotlib`) are listed under `[project.dependencies]` and locked via `uv.lock`.

## Using the C++ library from another CMake project

After installing this project (`cmake --install build --config Release`), you can

```
find_package(mylib CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE mylib::mylib)
```
