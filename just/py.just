set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

# Python checks used by continuous integration.
mod ci 'py/ci.just'

# Create or synchronize the locked Python environment.
sync:
    uv sync --locked

# Update the lockfile to the newest dependency versions allowed by the project.
upgrade:
    uv lock --upgrade

# Format all Python files.
format:
    uv run --locked ruff format .

# Check Python formatting without changing files.
format-check:
    uv run --locked ruff format --check .

# Lint all Python files.
lint:
    uv run --locked ruff check .

# Incrementally rebuild and reinstall the native Python extension.
rebuild:
    uv sync --locked --reinstall-package mylib-tools

# Validate the development install and a distributable wheel.
validate: ci::smoke ci::wheel

# Run the plotting CLI (usage: just py plot --save path).
plot *args:
    uv run --locked mylib-plot {{ args }}

# Run the CSV dump CLI (usage: just py dump --points 5 --output path).
dump *args:
    uv run --locked mylib-dump {{ args }}
