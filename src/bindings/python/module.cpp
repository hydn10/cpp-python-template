#include <pybind11/pybind11.h>

#include "mylib/mylib.hpp"

namespace py = pybind11;

PYBIND11_MODULE(_core, m) {
  m.doc() = "pybind11 bindings for mylib";

  m.def("compute_value", &mylib::compute_value,
        py::arg("x"),
        "Compute x*x + 1.0");
}

