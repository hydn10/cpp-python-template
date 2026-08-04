set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

# Run all available linters.
[default]
all: cpp py ci

# Run clang-tidy across every native target, including the Python binding.
cpp:
    cmake --preset python-quality --fresh
    cmake --build --preset python-quality --clean-first

# Run the Ruff linter across all Python files.
py:
    uv run --locked --only-group dev ruff check .

# Validate GitHub Actions workflows.
ci:
    actionlint
