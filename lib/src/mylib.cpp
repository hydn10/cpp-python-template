#include <mylib/mylib.hpp>

#include <Eigen/Core>

#include <cstddef>
#include <vector>


namespace mylib
{

double
compute_value(double x)
{
  return x * x + 1.0;
}


std::vector<double>
compute_values(double xmin, double xmax, std::size_t point_count)
{
  if (point_count == 0u)
  {
    return {};
  }

  std::vector<double> values(point_count);

  if (point_count == 1u)
  {
    values.front() = compute_value(xmin);
    return values;
  }

  auto const sample_count = static_cast<Eigen::Index>(values.size());
  auto const x_values = Eigen::ArrayXd::LinSpaced(sample_count, xmin, xmax);
  auto sampled_values = Eigen::Map<Eigen::ArrayXd>(values.data(), sample_count);

  // This helper evaluates the same scalar expression over a uniform grid,
  // which maps neatly to Eigen's array operations without changing the public API.
  sampled_values = x_values.unaryExpr(
      [](double x)
      {
        return compute_value(x);
      });

  return values;
}

} // namespace mylib
