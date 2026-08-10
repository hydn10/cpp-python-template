import argparse

from pathlib import Path
from typing import Optional, Sequence

from .sample_series import add_sample_range_arguments
from .sample_series import compute_sample_series
from .sample_series import parse_sample_grid


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = argparse.ArgumentParser(
        description="Dump mylib.compute_values samples as CSV"
    )
    add_sample_range_arguments(parser)
    parser.add_argument(
        "--output",
        type=str,
        default=None,
        help="Optional path to write CSV output. If omitted, writes to stdout",
    )
    args, sample_grid = parse_sample_grid(parser, argv)

    x_values, y_values = compute_sample_series(sample_grid)
    rows = ["x,y"] + [
        f"{x_value:.12g},{y_value:.12g}" for x_value, y_value in zip(x_values, y_values)
    ]
    csv_output = "\n".join(rows) + "\n"

    if args.output:
        Path(args.output).write_text(csv_output, encoding="utf-8")
    else:
        print(csv_output, end="")


if __name__ == "__main__":
    main()
