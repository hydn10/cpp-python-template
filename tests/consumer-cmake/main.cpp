#include <mylib/mylib.hpp>

#include <cmath>
#include <cstdio>


int
main()
{
  double const value = mylib::compute_value(3.0);
  if (std::abs(value - 10.0) > 1e-12)
  {
    std::fprintf(stderr, "unexpected compute_value result: %.17g\n", value);
    return 1;
  }

  return 0;
}
