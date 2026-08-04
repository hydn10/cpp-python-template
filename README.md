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
[pybind11](https://pybind11.readthedocs.io/) extension.

## Native C++

Requirements:

- [CMake](https://cmake.org/) >= 3.27
- [Ninja](https://ninja-build.org/)
- [Eigen](https://eigen.tuxfamily.org/) 3
- [C++23-capable compiler](https://en.cppreference.com/w/cpp/compiler_support/23)

The installed library itself requires only C++17. Native dependencies may be
provided by the host environment, [vcpkg](https://learn.microsoft.com/vcpkg/),
or [Nix](https://nixos.org/).

```sh
cmake --preset debug
cmake --build --preset debug
ctest --preset debug
./out/build/debug/apps/mylib-sample
```

For a distribution-oriented static Release build:

```sh
cmake --preset release
cmake --build --preset release
cmake --install out/build/release
```

Use `shared-release` instead of `release` to build a shared library.

Downstream CMake projects consume the installed package with:

```cmake
find_package(mylib CONFIG REQUIRED)

target_link_libraries(<target> PRIVATE mylib::mylib)
```

## Python tools

[Python](https://www.python.org/) 3.12 or newer and
[uv](https://docs.astral.sh/uv/) are required. uv uses an existing compatible
interpreter or downloads one when needed.

```sh
uv sync --locked
uv run --locked mylib-plot --save plot.png
uv run --locked mylib-dump --points 5 --output values.csv
```

After changing native code or bindings, rebuild the editable installation:

```sh
uv sync --locked --reinstall-package mylib-tools
```

## Native dependencies with vcpkg

Ensure `VCPKG_ROOT` points to a vcpkg checkout. Set it only if your environment
has not already done so.

PowerShell:

```powershell
# Only if VCPKG_ROOT is not already set:
$env:VCPKG_ROOT = "C:\path\to\vcpkg"

. .\tools\activate-vcpkg.ps1
```

POSIX shell:

```sh
# Only if VCPKG_ROOT is not already set:
export VCPKG_ROOT=/path/to/vcpkg

. tools/activate-vcpkg.sh
```

The adapter sets `CMAKE_TOOLCHAIN_FILE` so vcpkg supplies Eigen and, for direct
CMake Python builds, pybind11.

## Developer commands

[Just](https://just.systems/) exposes common workflows:

```sh
just help                 # discover all recipes
just cpp validate debug   # configure, build, check headers, and test
just py rebuild           # rebuild the Python development install
just format all           # format the repository
just check format all     # check repository formatting
just verify               # run the complete local verification
```

## Development environment

[Mise](https://mise.jdx.dev/) and [Nix](https://nixos.org/) are alternative
environment-provisioning approaches.

### Mise (selective)

With Mise activated in your shell:

```sh
mise install
just help
```

Alternatively, run a command inside the Mise environment:

```sh
mise x -- just help
```

Mise provides the repository’s portable workflow tooling.
Language toolchains, language-specific tools, runtimes, and project dependencies remain caller-provided.

### Nix (complete)

Nix provides a complete development environment.

```sh
nix develop       # enter the development environment
nix build         # build the default C++ library package
nix flake check   # run the flake's checks
```

The packaged applications can be run directly:

```sh
nix run .#mylib-sample
nix run .#mylib-plot
nix run .#mylib-dump
```

---

Repository design rationale lives in
[docs/repo-philosophy.md](docs/repo-philosophy.md).
