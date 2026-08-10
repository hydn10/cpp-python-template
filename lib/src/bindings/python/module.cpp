#include <nanobind/nanobind.h>
#include <nanobind/ndarray.h>

#include <mylib/mylib.hpp>

#include <cstddef>
#include <memory>
#include <utility>
#include <vector>


namespace nb = nanobind;


namespace
{

using values_array = nb::ndarray<nb::numpy, double, nb::ndim<1>, nb::c_contig>;

values_array
as_numpy_array(std::vector<double> values)
{
  auto owned_values = std::make_unique<std::vector<double>>(std::move(values));
  auto const element_count = owned_values->size();

  // Don't pass owned_values.release() since a failed capsule construction would leak it.
  nb::capsule const owner(
      owned_values.get(),
      [](void *pointer) noexcept
      {
        delete static_cast<std::vector<double> *>(pointer); // NOLINT(cppcoreguidelines-owning-memory)
      });

  auto *data = owned_values->data();
  owned_values.release(); // NOLINT(bugprone-unused-return-value)

  return values_array(data, {element_count}, owner);
}

} // namespace


NB_MODULE(_core, module)
{
  module.doc() = "Python bindings for mylib";

  module.def("compute_value", &mylib::compute_value, nb::arg("x"), "Compute x*x + 1.0.");
  module.def(
      "compute_values",
      [](double xmin, double xmax, std::size_t point_count)
      {
        return as_numpy_array(mylib::compute_values(xmin, xmax, point_count));
      },
      nb::arg("xmin"),
      nb::arg("xmax"),
      nb::arg("point_count"),
      "Sample compute_value() over an evenly spaced grid and return a NumPy array.");
}
