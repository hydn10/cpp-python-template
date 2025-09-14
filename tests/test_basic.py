import math


def test_compute_value_internal_binding():
    import mylib_apps._core as core

    x = 3.0
    out = core.compute_value(x)
    assert math.isclose(out, x * x + 1.0, rel_tol=1e-12, abs_tol=0.0)
