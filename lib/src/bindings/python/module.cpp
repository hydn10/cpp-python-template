// pybind11 headers need to be included first. See [1].
// [1]: https://pybind11.readthedocs.io/en/stable/basics.html#header-and-namespace-conventions
#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>

#include <mylib/mylib.hpp>

#include <algorithm>
#include <cstddef>
#include <vector>


namespace py = pybind11;


namespace
{

// pybind11's public umbrella headers intentionally provide these declarations.
// NOLINTBEGIN(misc-include-cleaner)
py::array_t<double>
as_numpy_array(std::vector<double> const &values)
{
  auto const element_count = static_cast<py::ssize_t>(values.size());
  auto result = py::array_t<double>(element_count);
  std::copy(values.cbegin(), values.cend(), result.mutable_data());
  return result;
}

} // namespace

PYBIND11_MODULE(_core, module)
{
  module.doc() = "pybind11 bindings for mylib";

  module.def("compute_value", &mylib::compute_value, py::arg("x"), "Compute x*x + 1.0.");
  module.def(
      "compute_values",
      [](double xmin, double xmax, std::size_t point_count)
  { return as_numpy_array(mylib::compute_values(xmin, xmax, point_count)); },
      py::arg("xmin"),
      py::arg("xmax"),
      py::arg("point_count"),
      "Sample compute_value() over an evenly spaced grid and return a NumPy array.");
}
// NOLINTEND(misc-include-cleaner)
