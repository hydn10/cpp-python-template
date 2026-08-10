import argparse
from dataclasses import dataclass
import os
from pathlib import Path
import re
import subprocess
import tomllib


@dataclass(frozen=True)
class CheckOptions:
    repository_root: Path
    work_dir: Path


@dataclass(frozen=True)
class ProjectMetadata:
    distribution_name: str
    import_package: str
    dump_script: str
    plot_script: str
    wheel_distribution_name: str

    @property
    def wheel_pattern(self) -> str:
        return f"{self.wheel_distribution_name}-*.whl"


@dataclass(frozen=True)
class WorkPaths:
    wheel_dir: Path
    venv_dir: Path
    run_dir: Path
    csv_output: Path
    plot_output: Path

    @property
    def outputs(self) -> tuple[Path, Path]:
        return self.csv_output, self.plot_output


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


def parse_args() -> CheckOptions:
    parser = argparse.ArgumentParser(
        description="Build and smoke-test the wheel in a fresh environment."
    )
    parser.add_argument("--repository-root", type=Path, required=True)
    parser.add_argument("--work-dir", type=Path, required=True)
    args = parser.parse_args()

    repository_root = args.repository_root.resolve()
    if not (repository_root / "pyproject.toml").is_file():
        parser.error(f"not a repository root: {repository_root}")

    output_root = (repository_root / "out").resolve()
    work_dir = (repository_root / args.work_dir).resolve()
    if output_root not in work_dir.parents:
        parser.error(f"work_dir must be beneath {output_root}")

    return CheckOptions(repository_root=repository_root, work_dir=work_dir)


def load_project_metadata(repository_root: Path) -> ProjectMetadata:
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

    return ProjectMetadata(
        distribution_name=distribution_name,
        import_package=import_package,
        dump_script=dump_script,
        plot_script=plot_script,
        wheel_distribution_name=wheel_distribution_name,
    )


def resolve_work_paths(work_dir: Path) -> WorkPaths:
    run_dir = work_dir / "run"
    return WorkPaths(
        wheel_dir=work_dir / "dist",
        venv_dir=work_dir / "venv",
        run_dir=run_dir,
        csv_output=run_dir / "values.csv",
        plot_output=run_dir / "plot.png",
    )


def prepare_work_area(paths: WorkPaths, wheel_pattern: str) -> None:
    paths.wheel_dir.mkdir(parents=True, exist_ok=True)
    paths.run_dir.mkdir(parents=True, exist_ok=True)

    for path in [*paths.wheel_dir.glob(wheel_pattern), *paths.outputs]:
        path.unlink(missing_ok=True)


def build_wheel(
    repository_root: Path, paths: WorkPaths, metadata: ProjectMetadata
) -> Path:
    run(
        "uv",
        "build",
        "--wheel",
        "--out-dir",
        paths.wheel_dir,
        cwd=repository_root,
    )

    wheels = list(paths.wheel_dir.glob(metadata.wheel_pattern))
    if len(wheels) != 1:
        raise RuntimeError(
            f"Expected one {metadata.distribution_name} wheel, found {len(wheels)}"
        )
    return wheels[0]


def create_venv_and_install(
    repository_root: Path, paths: WorkPaths, wheel: Path
) -> None:
    run(
        "uv",
        "venv",
        "--clear",
        "--no-project",
        paths.venv_dir,
        cwd=repository_root,
    )
    run(
        "uv",
        "pip",
        "install",
        "--python",
        paths.venv_dir,
        wheel,
        cwd=repository_root,
    )


def create_clean_environment() -> dict[str, str]:
    clean_env = os.environ.copy()
    clean_env.pop("PYTHONHOME", None)
    clean_env.pop("PYTHONPATH", None)
    return clean_env


def run_in_venv(*command, paths: WorkPaths, env: dict[str, str]) -> None:
    run(
        "uv",
        "run",
        "--no-project",
        "--python",
        paths.venv_dir,
        *command,
        cwd=paths.run_dir,
        env=env,
    )


def smoke_test_install(
    paths: WorkPaths, metadata: ProjectMetadata, env: dict[str, str]
) -> None:
    run_in_venv(
        "python",
        "-c",
        f"import {metadata.import_package}._core as core; print(core.__file__)",
        paths=paths,
        env=env,
    )
    run_in_venv(
        metadata.dump_script,
        "--points",
        "3",
        "--output",
        paths.csv_output,
        paths=paths,
        env=env,
    )
    run_in_venv(
        metadata.plot_script,
        "--points",
        "3",
        "--save",
        paths.plot_output,
        paths=paths,
        env=env,
    )


def verify_outputs(paths: WorkPaths) -> None:
    for output in paths.outputs:
        if not output.is_file() or output.stat().st_size == 0:
            raise RuntimeError(f"Expected a non-empty output: {output}")
        print(f"{output}: {output.stat().st_size} bytes")


def main() -> None:
    options = parse_args()
    metadata = load_project_metadata(options.repository_root)
    paths = resolve_work_paths(options.work_dir)

    prepare_work_area(paths, metadata.wheel_pattern)
    wheel = build_wheel(options.repository_root, paths, metadata)
    create_venv_and_install(options.repository_root, paths, wheel)
    smoke_test_install(paths, metadata, create_clean_environment())
    verify_outputs(paths)


if __name__ == "__main__":
    main()
