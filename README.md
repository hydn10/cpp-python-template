> [!NOTE]
> This repository is a project template. The README below documents the included
> example as a real project. Replace this notice and the project-specific content
> when adopting the template.

# mylib

`mylib` is a C++ library for evaluating the function $y = x^2 + 1$ at
individual values or across uniformly sampled intervals. It provides a reusable
native library, a C++ application, and Python command-line tools for printing,
exporting, and plotting the generated values.

The public API uses standard C++ types, while [Eigen](https://eigen.tuxfamily.org/)
handles batch evaluation internally:

```cpp
#include <mylib/mylib.hpp>

double const value = mylib::compute_value(2.0);
// 5.0

auto const values = mylib::compute_values(-1.0, 1.0, 5);
// {2.0, 1.25, 1.0, 1.25, 2.0}
```

The Python tools call the same native implementation through a private
[nanobind](https://nanobind.readthedocs.io/) extension.

## Native C++

Requirements:

- [CMake](https://cmake.org/) >= 4.3
- [Ninja](https://ninja-build.org/)
- [Eigen](https://eigen.tuxfamily.org/) 3
- [C++ compiler](https://en.cppreference.com/w/cpp/compiler_support/23) with C++23 support

The installed library itself requires only C++17. Native dependencies may be
supplied by the build environment, with built-in support for
[vcpkg](https://learn.microsoft.com/vcpkg/).

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
./out/build/debug/apps/mylib-sample
```

To use an existing `CMAKE_TOOLCHAIN_FILE`, select a generic preset (e.g. `debug`, not
`vcpkg-debug`). When changing external toolchains, reconfigure with --fresh or remove
the corresponding build directory.

For a distribution-oriented static Release build:

```sh
cmake --preset release
cmake --build --preset release
cmake --install out/build/release
```

Use `shared-release` instead of `release` to build a shared library.

Downstream CMake projects consume the installed CPS package with:

```cmake
find_package(mylib CONFIG REQUIRED)
target_link_libraries(<target> PRIVATE mylib::mylib)
```

## Python tools

[Python](https://www.python.org/) 3.12 or newer and
[uv](https://docs.astral.sh/uv/) are required. In the selective Mise workflow,
Mise supplies uv while uv selects an existing compatible interpreter or
downloads one when needed for Python package workflows.

Building the Python extension additionally requires [nanobind](https://nanobind.readthedocs.io/) >= 2.13.

```sh
uv sync --locked
uv run --locked mylib-plot --save plot.png
uv run --locked mylib-dump --points 5 --output values.csv
```

After changing native code or bindings, rebuild the editable installation:

```sh
uv sync --locked --reinstall-package mylib-tools
```

## vcpkg

[vcpkg](https://vcpkg.io/) can provision the project's native dependencies.

Set `VCPKG_ROOT` to a valid vcpkg checkout. The matching `vcpkg-*` presets then
become available to CMake. They use `cmake/toolchains/vcpkg.cmake`.

```sh
# If VCPKG_ROOT is not already set:
# export VCPKG_ROOT=/path/to/vcpkg

cmake --preset vcpkg-quality
cmake --build --preset vcpkg-quality
```

Direct CMake builds of the Python extension select the vcpkg `python` feature.
It declares both destination Python development artifacts and a runnable
build-machine interpreter. In vcpkg terminology, the latter is a host
dependency. Native builds deduplicate the two roles into one triplet. For a
cross build, set both `VCPKG_TARGET_TRIPLET` and `VCPKG_HOST_TRIPLET`. The
extension uses the target-triplet headers and libraries while CMake and
nanobind execute the host-triplet interpreter.

## Developer commands

[Just](https://just.systems/) exposes common workflows:

```sh
just help                 # discover all recipes
just cpp validate debug   # configure, build, check headers, and test
just py sync              # provider-aware Python environment
just py rebuild           # rebuild the Python development install
just format all           # format portable project files
just check format all     # check portable project formatting
just check lint all       # run all linting checks
just check                # run all read-only formatting and lint checks
just verify               # run complete read-only verification
```

With no preset argument, Just uses:

- Generic, when `CMAKE_TOOLCHAIN_FILE` is set (preserving that toolchain).
- The matching `vcpkg-*` preset, otherwise, when `VCPKG_ROOT` is set.
- Generic, when neither variable is set.

Explicit presets are literal: `just cpp build quality` is always `quality`.

Raw `uv` commands use the active workflow's uv: Mise in the selective workflow
and Nix in the Nix development shell. `just py ...` applies the provider-aware
defaults.

For a final pre-submission pass, consider running `just format all` followed by `just verify`.

## Development environment

[Mise](https://mise.jdx.dev/) and [Nix](https://nixos.org/) are alternative
environment-provisioning approaches.

### Mise (selective)

Use Mise's normal shell integration, or ensure its shims are on `PATH`:

```sh
mise install
just help
```

Alternatively, run a command inside the Mise environment:

```sh
mise x -- just help
```

On Windows, `mise x -- just format all` may fail because an upstream
command-resolution issue mishandles executable paths.

Mise provides the repository's portable development/build tooling, including
CMake, Ninja, uv, Just, and the repository quality tools. The caller remains
responsible for the native C++ platform toolchain.

Mise does not provision Python. `uv` owns interpreter
selection for Python package workflows. Provider-driven direct CMake builds may
use a provider-owned build interpreter matching their destination Python
artifacts. Project dependencies remain provider-specific.

### Nix (complete)

Nix provides a complete development environment.

```sh
nix develop       # enter the development environment
nix build         # build the default C++ library package
nix fmt           # format the Nix integration
nix flake check   # run the flake's checks, including Nix formatting
```

`nix fmt` formats the Nix integration separately from `just format all`.
`nix flake check` verifies its formatting.

The packaged applications can be run directly:

```sh
nix run .#mylib-sample
nix run .#mylib-plot
nix run .#mylib-dump
```

---

Repository design rationale lives in
[docs/repo-philosophy.md](docs/repo-philosophy.md).
