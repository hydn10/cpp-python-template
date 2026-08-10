set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

import '../common.just'

default-output-dir := "out/smoke/python"
default-wheel-work-dir := "out/smoke/wheel"

python-package := "mylib-tools"
plot-command := "mylib-plot"
dump-command := "mylib-dump"

[private]
prepare-output output_dir:
    cmake -E make_directory "{{ output_dir }}"

# Create or synchronize the locked Python environment.
sync preset=default-python-quality-preset: (run-uv preset "sync" "--locked")

# Update the lockfile to the newest dependency versions allowed by the project.
upgrade:
    uv lock --upgrade

# Incrementally rebuild and reinstall the native Python extension.
rebuild preset=default-python-quality-preset: (run-uv preset "sync" "--locked" "--reinstall-package" python-package)

# Validate the development install and a distributable wheel.
validate preset=default-python-quality-preset: (smoke preset default-output-dir) (check-wheel preset default-wheel-work-dir)

# Rebuild the locked package and smoke-test both console applications (usage: just py smoke [preset] [output_dir]).
smoke preset=default-python-quality-preset output_dir=default-output-dir: (prepare-output output_dir) (run-uv preset "sync" "--locked" "--reinstall-package" python-package) (run-uv preset "run" "--locked" dump-command "--points" "5" "--output" (output_dir + "/values.csv")) (run-uv preset "run" "--locked" plot-command "--points" "5" "--save" (output_dir + "/plot.png"))

# Build the wheel and smoke-test it in a fresh, non-project environment (usage: just py check-wheel [preset] [work_dir]).
check-wheel preset=default-python-quality-preset work_dir=default-wheel-work-dir: (run-uv preset "run" "--no-project" "python" "tools/checks/check-wheel.py" "--repository-root" "." "--work-dir" work_dir)

# Run the plotting CLI (usage: just py plot --save path).
plot *args: (run-uv default-python-quality-preset "run" "--locked" plot-command args)

# Run the CSV dump CLI (usage: just py dump --points 5 --output path).
dump *args: (run-uv default-python-quality-preset "run" "--locked" dump-command args)
