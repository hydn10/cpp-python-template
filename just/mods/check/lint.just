set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../../.."

import '../../common.just'

# Run all available linters.
[default]
all preset=default-python-quality-preset: (cpp preset) py ci

# Run clang-tidy across every native target, including the Python binding.
cpp preset=default-python-quality-preset:
    cmake --preset {{ preset }} --fresh
    cmake --build --preset {{ preset }} --clean-first

# Run the Ruff linter across all Python files.
py:
    uv run --locked --only-group dev ruff check .

# Validate GitHub Actions workflows.
ci:
    actionlint
