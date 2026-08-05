import argparse

from typing import Optional, Sequence

import matplotlib.pyplot as plt

from mylib_tools.sample_series import add_sample_range_arguments
from mylib_tools.sample_series import compute_sample_series
from mylib_tools.sample_series import parse_sample_grid


def main(argv: Optional[Sequence[str]] = None) -> None:
    parser = argparse.ArgumentParser(
        description="Plot mylib.compute_values over a range"
    )
    add_sample_range_arguments(parser)
    parser.add_argument(
        "--save",
        type=str,
        default=None,
        help="Optional path to save the plot (PNG). If omitted, shows the plot",
    )
    args, sample_grid = parse_sample_grid(parser, argv)

    x_values, y_values = compute_sample_series(sample_grid)

    plt.figure(figsize=(6, 4))
    plt.plot(x_values, y_values, label="x*x + 1")
    plt.title("mylib.compute_values")
    plt.xlabel("x")
    plt.ylabel("y")
    plt.grid(True, ls=":", alpha=0.6)
    plt.legend()
    plt.tight_layout()

    if args.save:
        plt.savefig(args.save, dpi=150)
    else:
        plt.show()


if __name__ == "__main__":
    main()
