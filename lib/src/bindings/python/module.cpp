#include <mylib/mylib.hpp>

#include <pybind11/numpy.h>
#include <pybind11/pybind11.h>

#include <algorithm>
#include <cstddef>
#include <vector>


namespace py = pybind11;


namespace
{

py::array_t<double>
as_numpy_array(std::vector<double> values)
{
  auto result = py::array_t<double>(values.size());
  std::copy(values.cbegin(), values.cend(), result.mutable_data());
  return result;
}

} // namespace

PYBIND11_MODULE(_core, m)
{
  m.doc() = "pybind11 bindings for mylib";

  m.def("compute_value", &mylib::compute_value, py::arg("x"), "Compute x*x + 1.0.");
  m.def(
      "compute_values",
      [](double xmin, double xmax, std::size_t point_count)
  { return as_numpy_array(mylib::compute_values(xmin, xmax, point_count)); },
      py::arg("xmin"),
      py::arg("xmax"),
      py::arg("point_count"),
      "Sample compute_value() over an evenly spaced grid and return a NumPy array.");
}
