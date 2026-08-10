import argparse
import os
from pathlib import Path
import re
import subprocess
import tomllib


def run(*command, cwd: Path, env=None) -> None:
    subprocess.run(
        [os.fspath(argument) for argument in command],
        cwd=cwd,
        env=env,
        check=True,
    )


def find_script_for_module(scripts: dict[str, str], module_name: str) -> str:
    suffix = f".{module_name}:main"
    matches = [name for name, target in scripts.items() if target.endswith(suffix)]
    if len(matches) != 1:
        raise RuntimeError(
            f"Expected one console script targeting *{suffix}, found {len(matches)}"
        )
    return matches[0]


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Build and smoke-test the wheel in a fresh environment."
    )
    parser.add_argument("--repository-root", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()

    repository_root = args.repository_root.resolve()
    if not (repository_root / "pyproject.toml").is_file():
        parser.error(f"not a repository root: {repository_root}")

    pyproject = tomllib.loads(
        (repository_root / "pyproject.toml").read_text(encoding="utf-8")
    )
    project_metadata = pyproject["project"]
    distribution_name = project_metadata["name"]
    scripts = project_metadata["scripts"]
    dump_script = find_script_for_module(scripts, "dump")
    plot_script = find_script_for_module(scripts, "plot")

    import_packages = {
        target.partition(":")[0].partition(".")[0] for target in scripts.values()
    }
    if len(import_packages) != 1:
        raise RuntimeError(
            "Expected every console script to target the same import package"
        )
    import_package = import_packages.pop()
    wheel_distribution_name = re.sub(r"[-_.]+", "_", distribution_name).lower()

    output_root = (repository_root / "out").resolve()
    work_dir = (repository_root / args.work_dir).resolve()
    if output_root not in work_dir.parents:
        parser.error(f"work_dir must be beneath {output_root}")

    wheel_dir = work_dir / "dist"
    venv_dir = work_dir / "venv"
    run_dir = work_dir / "run"
    csv_output = run_dir / "values.csv"
    plot_output = run_dir / "plot.png"

    wheel_dir.mkdir(parents=True, exist_ok=True)
    run_dir.mkdir(parents=True, exist_ok=True)

    wheel_pattern = f"{wheel_distribution_name}-*.whl"
    for path in [*wheel_dir.glob(wheel_pattern), csv_output, plot_output]:
        path.unlink(missing_ok=True)

    run("uv", "build", "--wheel", "--out-dir", wheel_dir, cwd=repository_root)

    wheels = list(wheel_dir.glob(wheel_pattern))
    if len(wheels) != 1:
        raise RuntimeError(
            f"Expected one {distribution_name} wheel, found {len(wheels)}"
        )
    wheel = wheels[0]

    run(
        "uv",
        "venv",
        "--clear",
        "--no-project",
        venv_dir,
        cwd=repository_root,
    )
    run(
        "uv",
        "pip",
        "install",
        "--python",
        venv_dir,
        wheel,
        cwd=repository_root,
    )

    clean_env = os.environ.copy()
    clean_env.pop("PYTHONHOME", None)
    clean_env.pop("PYTHONPATH", None)

    def run_in_venv(*command) -> None:
        run(
            "uv",
            "run",
            "--no-project",
            "--python",
            venv_dir,
            *command,
            cwd=run_dir,
            env=clean_env,
        )

    run_in_venv(
        "python",
        "-c",
        f"import {import_package}._core as core; print(core.__file__)",
    )
    run_in_venv(
        dump_script,
        "--points",
        "3",
        "--output",
        csv_output,
    )
    run_in_venv(
        plot_script,
        "--points",
        "3",
        "--save",
        plot_output,
    )

    for output in (csv_output, plot_output):
        if not output.is_file() or output.stat().st_size == 0:
            raise RuntimeError(f"Expected a non-empty output: {output}")
        print(f"{output}: {output.stat().st_size} bytes")


if __name__ == "__main__":
    main()
