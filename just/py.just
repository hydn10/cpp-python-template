set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := ".."

# Python checks used by continuous integration.
mod ci 'py/ci.just'

# Create or synchronize the locked Python environment.
sync:
    uv sync --locked

# Incrementally rebuild and reinstall the native Python extension.
rebuild:
    uv sync --locked --reinstall-package mylib-tools

# Run the plotting CLI (usage: just py plot --save path).
plot *args:
    uv run --locked mylib-plot {{ args }}

# Run the CSV dump CLI (usage: just py dump --points 5 --output path).
dump *args:
    uv run --locked mylib-dump {{ args }}
