#ifndef MYLIB_MYLIB_HPP
#define MYLIB_MYLIB_HPP

#include <cstddef>
#include <vector>

namespace mylib
{

double
compute_value(double x);


std::vector<double>
compute_values(double xmin, double xmax, std::size_t point_count);

} // namespace mylib

#endif
