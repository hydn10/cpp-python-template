#include <mylib/mylib.hpp>

#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>

#include <cstddef>
#include <memory>
#include <vector>


namespace nb = nanobind;


namespace
{

using samples_array = nb::ndarray<nb::numpy, double const, nb::ndim<1>, nb::c_contig>;

samples_array
as_numpy_array(std::vector<double> values)
{
  auto storage = std::make_unique<std::vector<double>>(std::move(values));
  auto *data = storage->data();
  auto const size = storage->size();
  nb::capsule owner(
      storage.release(), [](void *pointer) noexcept { delete static_cast<std::vector<double> *>(pointer); });
  return samples_array(data, {size}, owner);
}

} // namespace

NB_MODULE(_core, m)
{
  m.doc() = "nanobind bindings for mylib";

  m.def("compute_value", &mylib::compute_value, nb::arg("x"), "Compute x*x + 1.0.");
  m.def(
      "compute_values",
      [](double xmin, double xmax, std::size_t point_count)
  { return as_numpy_array(mylib::compute_values(xmin, xmax, point_count)); },
      nb::arg("xmin"),
      nb::arg("xmax"),
      nb::arg("point_count"),
      "Sample compute_value() over an evenly spaced grid and return a NumPy array.");
}
