import argparse
import numpy as np
import matplotlib.pyplot as plt

from ._core import compute_value


def main(argv: list[str] | None = None) -> None:
    parser = argparse.ArgumentParser(
        description="Plot mylib.compute_value over a range"
    )
    parser.add_argument("--xmin", type=float, default=-5.0, help="Minimum x value")
    parser.add_argument("--xmax", type=float, default=5.0, help="Maximum x value")
    parser.add_argument(
        "--points", type=int, default=201, help="Number of points in the range"
    )
    parser.add_argument(
        "--save",
        type=str,
        default=None,
        help="Optional path to save the plot (PNG). If omitted, shows the plot",
    )
    args = parser.parse_args(argv)

    x = np.linspace(args.xmin, args.xmax, args.points)
    y = np.array([compute_value(float(v)) for v in x], dtype=float)

    plt.figure(figsize=(6, 4))
    plt.plot(x, y, label="x*x + 1")
    plt.title("mylib.compute_value via pybind11")
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
