#include <mylib/mylib.hpp>

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
  if (point_count == 0U)
  {
    return {};
  }

  std::vector<double> values(point_count);
  if (point_count == 1U)
  {
    values.front() = compute_value(xmin);
    return values;
  }

  double const step = (xmax - xmin) / static_cast<double>(point_count - 1U);
  for (std::size_t index = 0; index < point_count; ++index)
  {
    double const x = xmin + (step * static_cast<double>(index));
    values[index] = compute_value(x);
  }

  return values;
}

} // namespace mylib
