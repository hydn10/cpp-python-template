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

See `docs/repo-philosophy.md` for the repository design principles.

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
- C++23-capable compiler to build this repo's applications and native tests
- C++17 is sufficient for downstream consumers of the installed `mylib` library target
- LLVM/clang-format and clang-tidy 22 for C++ formatting and static analysis
- Git for discovering the tracked C++ files passed to clang-format
- A provider for the native dependencies (currently Eigen3), such as Nix, a
  system package manager, or [vcpkg](https://learn.microsoft.com/vcpkg/)
- Python development files and pybind11 when using the `python-quality` preset
- Python 3.12+ and [uv](https://docs.astral.sh/uv/)
- Optionally, [Mise](https://mise.jdx.dev/) for general development tools
- Optionally, [Just](https://just.systems/) for the developer workflow façade (also provided by Mise and `nix develop`)

The checked-in configure presets do not select a dependency provider, compiler,
or machine-local path. In a Nix development shell, use them directly:

```bash
cmake --preset debug
```

For direct vcpkg use, set `VCPKG_ROOT` and select the repository's adapter
toolchain. The adapter delegates to vcpkg after translating enabled project
capabilities into vcpkg manifest features:

```bash
cmake --preset <preset> \
  --toolchain "$PWD/cmake/toolchains/vcpkg.cmake"
```

```powershell
cmake --preset <preset> `
  --toolchain "$PWD/cmake/toolchains/vcpkg.cmake"
```

The native target categories have independent CMake options:

- `MYLIB_BUILD_APPS` builds repository applications, which may be installed and packaged.
- `MYLIB_BUILD_EXAMPLES` builds consumption examples, which are never installed or exported.
- `MYLIB_BUILD_PYTHON` builds the Python extension module.
- `MYLIB_BUILD_TESTING` builds and registers native tests.

The application, example, and testing options default to enabled for a
top-level CMake build and disabled when `mylib` is included as a subproject.
The Python extension defaults to disabled in every ordinary CMake build.

## Native presets and dependency providers

There are five cross-platform configure presets:

| Preset           | Build type | Linkage | Static analysis | Python extension |
| ---------------- | ---------- | ------- | --------------- | ---------------- |
| `debug`          | Debug      | Static  | Off             | Off              |
| `quality`        | Debug      | Static  | clang-tidy      | Off              |
| `python-quality` | Debug      | Static  | clang-tidy      | On               |
| `release`        | Release    | Static  | Off             | Off              |
| `shared-release` | Release    | Shared  | Off             | Off              |

All five build the native applications, examples, and tests. `python-quality`
inherits the quality configuration, enables position-independent code, and
also builds the `_core` extension so its binding source receives clang-tidy
coverage. It is a direct CMake diagnostic workflow, not a replacement for the
uv/scikit-build-core installation and wheel workflows.

The checked-in presets express project intent only. When the vcpkg adapter at
`cmake/toolchains/vcpkg.cmake` is selected by the environment, direct CMake
builds map `MYLIB_BUILD_PYTHON=ON` to the `python` feature in `vcpkg.json`.
Scikit-build-core instead supplies Python and pybind11 from its isolated build
environment, while vcpkg continues to provide the core Eigen dependency.
Other environments provide these dependencies directly and use the same
presets without loading the adapter.

A CMake preset cannot turn an arbitrary command-line toolchain path into a
short, safe `binaryDir` component. Reusing one CMake cache after changing
dependency providers, compilers, or toolchains is unsafe. The repository keeps
the checked-in presets and Just recipes provider-neutral and adopts a simple
rule: clean the affected native and Python build trees before making such a
change.

| Design considered                                 | Decision                                                                           |
| ------------------------------------------------- | ---------------------------------------------------------------------------------- |
| Provider-specific directories selected by Just    | Rejected: provider routing does not belong in the task runner.                     |
| Clean before switching provider/toolchain         | Adopted: explicit, portable, and no hidden state.                                  |
| Provider-specific `CMakeUserPresets.json` entries | Optional for users who switch frequently, but not required.                        |
| Derive a directory suffix in checked-in presets   | Rejected: preset macros cannot safely normalize or hash arbitrary toolchain paths. |

For example, before changing the environment used by `quality`:

```bash
just purge-out
```

This also discards scikit-build-core's persistent native build cache. For a
selective cleanup, remove `out/build/quality`, `out/install/quality`, and
`out/_skbuild` directly. Then activate or enter the new dependency environment
and configure again. For an ordinary CMake cache reset that does not change
dependency providers, use `just cpp configure quality --fresh`.

Each configure preset has a matching build and test preset. This keeps the
build-directory association and test failure policy in CMake instead of
duplicating them in Just. Workflow presets remain intentionally absent: they
would repeat the same three-step sequence for every configuration, while Just
already composes it and the underlying commands remain ordinary CMake and
CTest:

```bash
cmake --preset quality
cmake --build --preset quality
cmake --build --preset quality --target all_verify_interface_header_sets
ctest --preset quality
```

Use `debug` in those commands for a faster Debug check without static analysis,
`python-quality` to include the Python extension in the quality checks, `release`
for a static Release check, or `shared-release` for shared-library
verification.

## Developer workflows with Just

The root `justfile` is an optional façade over CMake, CTest, uv, and the
project's console scripts. It does not select a dependency provider: every
recipe uses the current shell environment, just like its raw command.

| Recipe                                             | Delegated operation                                                              |
| -------------------------------------------------- | -------------------------------------------------------------------------------- |
| `cpp format` / `cpp format-check`                  | Apply or check clang-format on every tracked C++ source and header               |
| `cpp lint`                                         | Run clang-tidy across every native target, including the Python binding          |
| `cpp configure [preset] [--fresh]`                 | Configure the preset, optionally from a fresh CMake cache                        |
| `cpp build [preset]`                               | Build its native tree                                                            |
| `cpp clean [preset]`                               | Run the configured tree's clean target                                           |
| `cpp verify-headers [preset]`                      | Verify that each public header is self-contained                                 |
| `cpp test [preset]`                                | Run its native tests                                                             |
| `cpp validate [preset]`                            | Freshly configure, cleanly build, validate public headers, and test              |
| `cpp ci check-installed [release\|shared-release]` | Install a Release native build, then build and run the CMake consumer against it |
| `py format` / `py format-check`                    | Apply or check Ruff's Python formatter                                           |
| `py lint`                                          | Run the Ruff linter                                                              |
| `py sync`                                          | Create or synchronize the locked Python environment                              |
| `py upgrade`                                       | Update `uv.lock` to the newest dependency versions allowed by the project        |
| `py rebuild`                                       | Incrementally rebuild and reinstall the extension                                |
| `py validate`                                      | Validate the rebuilt development install and a distributable wheel               |
| `py plot [arguments]` / `py dump [arguments]`      | Run a locked Python CLI                                                          |
| `py ci smoke [output-directory]`                   | Rebuild and smoke-test both Python console applications                          |
| `py ci wheel [work-directory]`                     | Build a wheel and smoke-test it in a fresh environment                           |
| `format-misc` / `format-check-misc`                | Apply or check Just and dprint formatting for miscellaneous files                |
| `format` / `format-check`                          | Apply or check every repository formatter                                        |
| `quality`                                          | Check all formatting, then run C++ and Python linting                            |
| `verify`                                           | Run formatting, linting, native, Python application, and wheel checks            |
| `purge-out`                                        | Delete the entire `out/` directory                                               |
| `purge-all`                                        | Delete disposable build state, environments, caches, and package outputs         |

`py sync` is primarily an environment bootstrap and repair command. It creates
`.venv` when necessary, installs the versions from `uv.lock`, removes
undeclared packages, and installs this project editably. Normal `uv run`
commands already check and synchronize the environment, so `py sync` is not a
required prelude to every application run.

`just quality` is the static-quality entry point: it checks every formatter and
explicitly runs clang-tidy and Ruff. `just verify` is the convenient local
approximation of the repository's complete CI checks: it also runs the native
verification, rebuilds and smoke-tests the locked Python development install,
and builds and smoke-tests a wheel in a fresh environment. Both commands use
the comprehensive `python-quality` configuration, covering the ordinary native
targets and the Python binding. CI invokes the underlying recipes separately
where its platform matrices differ.

General native recipes default to the `quality` preset, while `cpp lint` always
uses `python-quality` for complete clang-tidy coverage. Pass `debug` explicitly
to native build or verification recipes when a faster Debug build without
clang-tidy is preferable. C++ formatting uses `git ls-files` to pass every
tracked C or C++ source and header to clang-format, leaving generated and
untracked files untouched. Python formatting and linting use the Ruff version
declared by the development dependency group and locked in `uv.lock`. Mise and
Nix may provide the general tools, but recipes invoke those tools directly from
the active environment.

Editable installation makes Python-source changes visible immediately, but it
does not automatically recompile the C++ extension. After changing native
sources, headers, bindings, or relevant CMake files, run `py rebuild`; it
forces reinstallation of this project while reusing scikit-build-core's
persistent native build tree.

Inside the Nix development environment, Nix provides the dependencies and
tools, while Just provides the same command vocabulary used elsewhere:

```bash
nix develop
just cpp validate
just cpp validate python-quality
just py rebuild
```

For a vcpkg-backed shell, set `VCPKG_ROOT` and source the small activation
helper once from the repository root. It exports CMake's standard
`CMAKE_TOOLCHAIN_FILE` pointing to the repository adapter, so raw CMake,
uv/scikit-build-core, IDEs launched from that shell, and Just all see the same
provider. The adapter activates vcpkg's optional `python` feature automatically
when the selected configuration enables `MYLIB_BUILD_PYTHON`:

```bash
source tools/activate-vcpkg.sh
just cpp validate
just cpp validate python-quality
just py rebuild
```

```powershell
. .\tools\activate-vcpkg.ps1
just cpp validate
just cpp validate python-quality
just cpp validate release
just cpp validate shared-release
just py rebuild
```

The helpers must be sourced (or dot-sourced), not executed as child processes.
They are vcpkg conveniences, not requirements of Just, and they never modify
the committed presets. Other providers can prepare an environment in their
native way; for example, a generated Conan CMake toolchain can be exposed
through the same standard CMake variable.

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

Run `just cpp validate [preset]`, or use the raw configure, build, public-header
verification, and CTest commands shown above. The normal build compiles the
library, applications, examples, and native test executables; CTest runs only
the explicitly registered native tests. Static Debug with or without the
quality tooling, quality checks that include the Python extension, static
Release, and shared Release checks are all local workflows; broader compiler
and platform combinations remain CI concerns.

The installed CMake package has a separate, minimal consumer check. After
building the `release` or `shared-release` preset, run
`just cpp ci check-installed [release|shared-release]`, or use the underlying
commands directly:

```bash
cmake --install out/build/release
cmake -S tests/consumer-cmake -B out/build/consumer-cmake/release \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH=/path/to/repository/out/install/release
cmake --build out/build/consumer-cmake/release
ctest --test-dir out/build/consumer-cmake/release \
  --output-on-failure \
  --no-tests=error
```

Use `shared-release` in the build and install paths to check the shared
package. `CMAKE_PREFIX_PATH` must be absolute because CMake interprets relative
package-search paths from the consumer build tree. On Windows, the consumer
stages the imported package's runtime DLLs before CTest runs it.

CI expresses coverage as data-driven toolchain lanes. Every ordinary Linux and
Windows lane runs the locked Python application smoke check, static and shared
Release native checks, and both installed-package consumer checks.
Comprehensive lanes additionally run the `python-quality` preset. It is a superset
of `quality`, so those lanes apply clang-tidy to every ordinary native target
and the Python binding without building the two configurations separately. A
future toolchain can opt into the comprehensive suite by changing its matrix
entry rather than duplicating the workflow.

## Static Analysis (clang-tidy 22)

- LLVM 22 is required; configuration lives in `.clang-tidy` (tweak checks as needed).
- The `quality` preset enables clang-tidy automatically and treats all findings
  as errors, so normal incremental developer builds run static analysis:

  ```bash
  cmake --preset quality
  cmake --build --preset quality
  ```

- The `debug` preset uses the same Debug build configuration without static
  analysis. Pass it explicitly to a Just recipe when a quicker incremental
  build is more useful than immediate analysis feedback.
- The `python-quality` preset extends `quality` with the `_core` extension, providing
  clang-tidy coverage for the pybind11 binding source.
- Static analysis remains caller policy and can be enabled for another preset
  when needed:

  ```bash
  cmake --preset release \
    -DCMAKE_CXX_CLANG_TIDY='clang-tidy;--warnings-as-errors=*' \
    -DCMAKE_EXPORT_COMPILE_COMMANDS=ON
  cmake --build --preset release
  ```

- Add the documented `--toolchain` argument when vcpkg is the dependency
  provider. The `quality` preset adds `--extra-arg=/EHsc` automatically on
  Windows. When enabling clang-tidy manually for a Windows build, append that
  argument to `CMAKE_CXX_CLANG_TIDY` as well.
- To invoke it manually, use `clang-tidy -p out/build/quality ...` or
  `run-clang-tidy -p out/build/quality`.

## Nix (flake)

This repo includes a per-system Nix flake currently supporting
`x86_64-linux`.

- Build the C++ library (default package):
  - `nix build` → result is the installed library in `result/`
- Build the C++ library and native application:
  - `nix build .#mylib-native-apps`
- Build all native targets, verify the public headers, and run the registered
  native tests:
  - `nix flake check`
- Run the native application:
  - `nix run .#mylib-sample`
- Run the Python plotting app:
  - `nix run .#mylib-plot`
- Run the Python CSV dump app:
  - `nix run .#mylib-dump`
- Build the packaged Python application:
  - `nix build .#python-apps`
- Enter a development shell with C++, Python, uv, and Just available:
  - `nix develop`

Notes:

- The Python application is built using uv2nix from `uv.lock` and
  `pyproject.toml`. Its package output uses pyproject-nix's `mkApplication` so
  the virtual environment remains an internal implementation detail.
- The dev shell is uv-first: it provides the C++ toolchain, Eigen, LLVM 22
  tools, dprint, pybind11, `uv`, Just, and a pinned Nix Python interpreter, but
  it does not put the packaged Python application on `PATH`. Inside `nix develop`, use
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
- Python packaging declares pybind11 in `pyproject.toml`, so its isolated build
  environment provides it automatically. A direct `python-quality` CMake build
  instead uses the active native provider: the vcpkg adapter selects the
  manifest's `python` feature, while the Nix development shell supplies
  pybind11 directly.
- Eigen is a native project dependency, not a Python build requirement. In a
  Nix shell, CMake discovers the Nix-provided package. With vcpkg, source the
  activation helper before running either raw uv or Just commands.
- Clean `out/_skbuild` before switching dependency provider, compiler,
  toolchain, or another incompatible native environment. This explicit
  cleanup is the Python counterpart of cleaning a native preset tree.
- The project version used by the C++ build and Python distribution metadata is read from `vcpkg.json`.
- The console app runtime deps (`numpy`, `matplotlib`) are listed under `[project.dependencies]` and locked via `uv.lock`.
- `just py ci wheel [work-dir]` builds and checks a normal wheel in a fresh
  environment under `out/smoke/wheel` by default.

## Using the C++ library from another CMake project

After installing this project (`cmake --install out/build/release`), you can

```
find_package(mylib CONFIG REQUIRED)
target_link_libraries(your_target PRIVATE mylib::mylib)
```

The install exports only `mylib::mylib`. If `MYLIB_BUILD_APPS=ON`, it also installs
`mylib-sample` as a runtime application; examples are never installed.
