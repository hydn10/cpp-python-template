"""Shared helpers for Python console apps built on top of mylib."""

from __future__ import annotations

import argparse
from dataclasses import dataclass
from typing import Optional, Sequence

import numpy as np

from ._core import compute_values


@dataclass(frozen=True)
class SampleGrid:
    xmin: float
    xmax: float
    points: int


def add_sample_range_arguments(parser: argparse.ArgumentParser) -> None:
    parser.add_argument("--xmin", type=float, default=-5.0, help="Minimum x value")
    parser.add_argument("--xmax", type=float, default=5.0, help="Maximum x value")
    parser.add_argument(
        "--points", type=int, default=201, help="Number of points in the range"
    )


def parse_sample_grid(
    parser: argparse.ArgumentParser, argv: Optional[Sequence[str]] = None
) -> tuple[argparse.Namespace, SampleGrid]:
    args = parser.parse_args(argv)
    if args.points < 1:
        parser.error("--points must be at least 1")

    return args, SampleGrid(
        xmin=args.xmin,
        xmax=args.xmax,
        points=args.points,
    )


def compute_sample_series(sample_grid: SampleGrid) -> tuple[np.ndarray, np.ndarray]:
    x_values = np.linspace(sample_grid.xmin, sample_grid.xmax, sample_grid.points)
    y_values = np.asarray(
        compute_values(sample_grid.xmin, sample_grid.xmax, sample_grid.points),
        dtype=float,
    )
    return x_values, y_values
