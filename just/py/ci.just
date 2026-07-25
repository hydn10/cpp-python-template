set windows-shell := ["powershell.exe", "-NoLogo", "-NoProfile", "-Command"]
set working-directory := "../.."

default-output-dir := "out/smoke/python"

[private]
prepare-output output_dir:
    cmake -E make_directory "{{ output_dir }}"

# Rebuild the locked package and smoke-test both console applications.
smoke output_dir=default-output-dir: (prepare-output output_dir)
    uv sync --locked --reinstall-package mylib-tools
    uv run --locked mylib-dump --points 3 --output "{{ output_dir }}/values.csv"
    uv run --locked mylib-plot --points 3 --save "{{ output_dir }}/plot.png"
