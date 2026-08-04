set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

default-output-dir := "out/smoke/python"
default-wheel-work-dir := "out/smoke/wheel"

[private]
prepare-output output_dir:
    cmake -E make_directory "{{ output_dir }}"

# Create or synchronize the locked Python environment.
sync:
    uv sync --locked

# Update the lockfile to the newest dependency versions allowed by the project.
upgrade:
    uv lock --upgrade

# Incrementally rebuild and reinstall the native Python extension.
rebuild:
    uv sync --locked --reinstall-package mylib-tools

# Validate the development install and a distributable wheel.
validate: smoke check-wheel

# Rebuild the locked package and smoke-test both console applications.
smoke output_dir=default-output-dir: (prepare-output output_dir)
    uv sync --locked --reinstall-package mylib-tools
    uv run --locked mylib-dump --points 3 --output "{{ output_dir }}/values.csv"
    uv run --locked mylib-plot --points 3 --save "{{ output_dir }}/plot.png"

# Build the wheel and smoke-test it in a fresh, non-project environment.
check-wheel work_dir=default-wheel-work-dir:
    uv run --no-project python tools/checks/check-wheel.py --repository-root . --work-dir "{{ work_dir }}"

# Run the plotting CLI (usage: just py plot --save path).
plot *args:
    uv run --locked mylib-plot {{ args }}

# Run the CSV dump CLI (usage: just py dump --points 5 --output path).
dump *args:
    uv run --locked mylib-dump {{ args }}
