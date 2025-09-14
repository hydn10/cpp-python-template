# mylib — Minimal C++ library with Python apps

This is a minimal example of a C++ library that is consumable from both C++ and Python. It uses modern CMake for the C++ project, and pybind11 + scikit-build-core for the Python extension. Python workflows use UV.

The library exposes a single function:

```
double mylib::compute_value(double x);  // returns x*x + 1.0
```

Python here is an application wrapper only. The internal extension is not a public API; use the provided console scripts.

## Layout

- `include/mylib/mylib.hpp` — public C++ header
- `src/mylib.cpp` — C++ library implementation
- `examples/cpp_example.cpp` — tiny C++ app using the library
- `src/bindings/python/module.cpp` — pybind11 module definition
- `python/mylib_apps/` — Python application package (console scripts), internal extension at `_core`
- `CMakeLists.txt` — modern CMake project (installs C++ library + headers)
- `pyproject.toml` — scikit-build-core configuration for Python packaging

## Prereqs

- C++17-capable compiler and CMake >= 3.21
- Python 3.8+ and [uv](https://github.com/astral-sh/uv)

## Build and run the C++ example

```
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build --config Release --target mylib_example

# Run (Windows):
build/Release/mylib_example.exe

# Run (Linux/macOS):
./build/mylib_example
```

## Python apps with UV (locked env)

This repo treats Python as an application wrapper for visualization, so we recommend locking dependencies for reproducibility.

```
# 1) Create/update a lockfile from pyproject.toml
uv lock

# 2) Create/sync the environment strictly to the lockfile
uv sync --frozen

# 3) Install this project (builds the C++ extension via scikit-build-core)
uv pip install -e .

# Plotting demo (installed console script)
uv run mylib-plot
# With options
# uv run mylib-plot --xmin -10 --xmax 10 --points 401 --save plot.png

# Optional: include dev tools (pytest) in the lock and env
# uv lock --extra dev
# uv sync --frozen --extra dev
# uv run pytest -q
```

Notes:

- The Python build requires `pybind11` (declared in `pyproject.toml`) and will be provided automatically during build.
- When building C++ only (not via scikit-build-core), the Python extension is not required and will be skipped unless you pass `-DBUILD_PYTHON=ON` and have pybind11 available to CMake.
- The application’s Python deps (`numpy`, `matplotlib`) are listed under `[project.dependencies]` and are locked via `uv.lock`.

Advanced

- Internal import for debugging only (not API):
  - `uv run python -c "import mylib_apps._core as m; print(m.compute_value(3.0))"`

## Using the C++ library from another CMake project

After installing this project (`cmake --install build --config Release`), you can

```
find_package(mylib CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE mylib::mylib)
```
