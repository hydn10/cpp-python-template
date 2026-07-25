# mylib — Minimal C++ library with native and Python apps

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
- `apps/sample.cpp` — installed first-party native application
- `examples/basic_usage.cpp` — minimal, noninstalled C++ consumption example
- `lib/src/bindings/python/module.cpp` — pybind11 module definition
- `python/src/mylib_tools/` — Python tool package, including the private extension at `_core`
- `CMakeLists.txt` — modern CMake project (installs C++ library + headers)
- `pyproject.toml` — scikit-build-core configuration for Python packaging

## Prereqs

- CMake >= 3.27
- Ninja
- C++23-capable compiler to build this repo's examples/tests
- C++17 is sufficient for downstream consumers of the installed `mylib` library target
- LLVM/clang-tidy 22 when using the `debug` preset or otherwise enabling static analysis
- A provider for the native dependencies (currently Eigen3), such as Nix, a
  system package manager, or [vcpkg](https://learn.microsoft.com/vcpkg/)
- Python 3.9+ and [uv](https://docs.astral.sh/uv/)
- Optionally, [Just](https://just.systems/) for the developer workflow façade (also provided by `nix develop`)

The checked-in configure presets do not select a dependency provider, compiler,
or machine-local path. In a Nix development shell, use them directly:

```bash
cmake --preset debug
```

For direct vcpkg use, set `VCPKG_ROOT` and supply its toolchain on the command
line:

```bash
cmake --preset <preset> \
  --toolchain "$VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
```

```powershell
cmake --preset <preset> `
  --toolchain "$env:VCPKG_ROOT/scripts/buildsystems/vcpkg.cmake"
```

The native target categories have independent CMake options:

- `MYLIB_BUILD_APPS` builds repository applications, which may be installed and packaged.
- `MYLIB_BUILD_EXAMPLES` builds consumption examples, which are never installed or exported.
- `MYLIB_BUILD_TESTING` builds and registers native tests.

All three default to enabled for a top-level CMake build and disabled when `mylib` is included as a subproject.

## Native presets and dependency providers

There are three cross-platform configure presets:

| Preset | Build type | Linkage | Static analysis |
| --- | --- | --- | --- |
| `debug` | Debug | Static | clang-tidy |
| `release` | Release | Static | Off |
| `shared-release` | Release | Shared | Off |

All three build the native applications, examples, and tests. They explicitly
leave the Python extension off; Python packaging owns that build.

A CMake preset cannot turn an arbitrary command-line toolchain path into a
short, safe `binaryDir` component. Reusing one CMake cache after changing
dependency providers, compilers, or toolchains is unsafe. The repository keeps
the checked-in presets and Just recipes provider-neutral and adopts a simple
rule: clean the affected native and Python build trees before making such a
change.

| Design considered | Decision |
| --- | --- |
| Provider-specific directories selected by Just | Rejected: provider routing does not belong in the task runner. |
| Clean before switching provider/toolchain | Adopted: explicit, portable, and no hidden state. |
| Provider-specific `CMakeUserPresets.json` entries | Optional for users who switch frequently, but not required. |
| Derive a directory suffix in checked-in presets | Rejected: preset macros cannot safely normalize or hash arbitrary toolchain paths. |

For example, before changing the environment used by `debug`:

```bash
just cpp rm debug
cmake -E remove_directory out/_skbuild
```

The second command discards scikit-build-core's persistent native build cache.
If Just is unavailable, remove `out/build/debug` and `out/install/debug`
directly. Then activate or enter the new dependency environment and configure
again.

Each configure preset has a matching build and test preset. This keeps the
build-directory association and test failure policy in CMake instead of
duplicating them in Just. Workflow presets remain intentionally absent: they
would repeat the same three-step sequence for every configuration, while Just
already composes it and the underlying commands remain ordinary CMake and
CTest:

```bash
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
```

Use `release` in those commands for a static Release check, or
`shared-release` for shared-library verification.

## Developer workflows with Just

The root `justfile` is an optional façade over CMake, CTest, uv, and the
project's console scripts. It does not select a dependency provider: every
recipe uses the current shell environment, just like its raw command.

| Recipe | Delegated operation |
| --- | --- |
| `cpp configure [preset]` | Configure the preset |
| `cpp build [preset]` | Build its native tree |
| `cpp clean [preset]` | Run the configured tree's clean target |
| `cpp verify-headers [preset]` | Verify that each public header is self-contained |
| `cpp test [preset]` | Run its native tests |
| `cpp check [preset]` | Configure, build, verify public headers, and test |
| `cpp rm [preset]` | Remove that preset's build and install trees |
| `py sync` | Create or synchronize the locked Python environment |
| `py rebuild` | Incrementally rebuild and reinstall the extension |
| `py plot [arguments]` / `py dump [arguments]` | Run a locked Python CLI |
| `py ci smoke [output-directory]` | Rebuild and smoke-test both Python console applications |
| `rm-out` | Delete the entire `out/` directory |
| `check [preset]` | Check native C++ and smoke-test the rebuilt Python applications |

`py sync` is primarily an environment bootstrap and repair command. It creates
`.venv` when necessary, installs the versions from `uv.lock`, removes
undeclared packages, and installs this project editably. Normal `uv run`
commands already check and synchronize the environment, so `py sync` is not a
required prelude to every application run.

Editable installation makes Python-source changes visible immediately, but it
does not automatically recompile the C++ extension. After changing native
sources, headers, bindings, or relevant CMake files, run `py rebuild`; it
forces reinstallation of this project while reusing scikit-build-core's
persistent native build tree.

Inside the Nix development environment, Nix provides the dependencies and
tools, while Just provides the same command vocabulary used elsewhere:

```bash
nix develop
just cpp check
just py rebuild
```

For a vcpkg-backed shell, set `VCPKG_ROOT` and source the small activation
helper once. It exports CMake's standard `CMAKE_TOOLCHAIN_FILE`, so raw CMake,
uv/scikit-build-core, and Just all see the same provider:

```bash
source tools/activate-vcpkg.sh
just cpp check
just py rebuild
```

```powershell
. .\tools\Activate-Vcpkg.ps1
just cpp check
just cpp check release
just cpp check shared-release
just py rebuild
```

The helpers must be sourced (or dot-sourced), not executed as child processes.
They are vcpkg conveniences, not requirements of Just. Other providers can
prepare an environment in their native way; for example, a generated Conan
CMake toolchain can be exposed through the same standard CMake variable.

CLI options are passed through:

```bash
just py plot --save plot.png
just py dump --points 5 --output values.csv
```

## Build and run the native application and example

After configuring and building one of the raw preset trees:

```bash
./out/build/debug/apps/mylib-sample
./out/build/debug/examples/mylib-basic-usage-example
```

With Just, the path is unchanged:

```bash
./out/build/debug/apps/mylib-sample
```

On Windows the corresponding executables end in `.exe`.

## Testing

Run `just cpp check [preset]`, or use the raw configure, build, public-header
verification, and CTest commands shown above. The normal build compiles the
library, applications, examples, and native test executables; CTest runs only
the explicitly registered native tests. Static Debug, static Release, and
shared Release checks are all local workflows; broader compiler and platform
combinations remain CI concerns.

CI expresses native coverage as data-driven toolchain lanes. Comprehensive
lanes run Debug with clang-tidy and the Python application smoke check in
addition to static and shared Release. Compatibility lanes run the two Release
native configurations. A future toolchain can opt into the comprehensive suite
by changing its matrix entry rather than duplicating the workflow.

## Static Analysis (clang-tidy 22)

- LLVM 22 is required; configuration lives in `.clang-tidy` (tweak checks as needed).
- The `debug` preset enables clang-tidy automatically and treats all findings
  as errors, so normal incremental developer builds run static analysis:

  ```bash
  cmake --preset debug
  cmake --build --preset debug
  ```

- Static analysis remains caller policy and can be enabled for another preset
  when needed:

  ```bash
  cmake --preset release \
    -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*' \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  cmake --build --preset release
  ```

- Add the documented `--toolchain` argument when vcpkg is the dependency
  provider. The `debug` preset adds `--extra-arg=/EHsc` automatically when
  the C++ compiler is MSVC. When enabling clang-tidy manually for an MSVC
  build, append that argument to `CMAKE_CXX_CLANG_TIDY` as well.
- To invoke it manually, use `clang-tidy -p out/build/debug ...` or
  `run-clang-tidy -p out/build/debug`.

## Nix (flake)

This repo includes a Nix flake targeting `x86_64-linux`.

- Build the C++ library (default package):
  - `nix build` → result is the installed library in `result/`
- Build the C++ library and native application:
  - `nix build .#mylib-apps`
- Build all native targets, verify the public headers, and run the registered
  native tests:
  - `nix flake check`
- Run the native application:
  - `nix run .#mylib-sample`
- Run the Python plotting app:
  - `nix run .#mylib-plot`
- Run the Python CSV dump app:
  - `nix run .#mylib-dump`
- Build the packaged Python apps environment:
  - `nix build .#python-apps`
- Enter a development shell with C++, Python, uv, and Just available:
  - `nix develop`

Notes:

- The Python apps are built using uv2nix from `uv.lock` and `pyproject.toml`.
- The dev shell is uv-first: it provides the C++ toolchain, Eigen, LLVM 22
  tools, `uv`, Just, and a pinned Nix Python interpreter, but it does not put
  the packaged Python apps environment on `PATH`. Inside `nix develop`, use
  `just py sync` (or raw `uv sync --locked`) and normal `just py plot` /
  `just py dump` commands. The shell also exposes Nix-provided `tkinter` plus the
  X11/Wayland client libraries so uv-managed `matplotlib` can open interactive
  windows on Nix.
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

- `uv sync --locked` installs the project in editable mode, so there is no separate `uv pip install -e .` step.
- After changes to C++ sources, headers, bindings, or relevant CMake files,
  run `just py rebuild`, or its raw equivalent:

  ```bash
  uv sync --locked --reinstall-package mylib-tools
  ```

  scikit-build-core keeps its intermediate CMake/Ninja tree under
  `out/_skbuild/{wheel_tag}`. Reinstalling therefore performs an incremental
  native build instead of starting from scratch; the wheel tag separates
  Python ABI and platform combinations.
- The Python build requires `pybind11` and will be provided automatically from `pyproject.toml`.
- Eigen is a native project dependency, not a Python build requirement. In a
  Nix shell, CMake discovers the Nix-provided package. With vcpkg, source the
  activation helper before running either raw uv or Just commands.
- Clean `out/_skbuild` before switching dependency provider, compiler,
  toolchain, or another incompatible native environment. This explicit
  cleanup is the Python counterpart of cleaning a native preset tree.
- The project version used by the C++ build and Python distribution metadata is read from `vcpkg.json`.
- The console app runtime deps (`numpy`, `matplotlib`) are listed under `[project.dependencies]` and locked via `uv.lock`.

## Using the C++ library from another CMake project

After installing this project (`cmake --install out/build/release`), you can

```
find_package(mylib CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE mylib::mylib)
```

The install exports only `mylib::mylib`. If `MYLIB_BUILD_APPS=ON`, it also installs
`mylib-sample` as a runtime application; examples are never installed.
