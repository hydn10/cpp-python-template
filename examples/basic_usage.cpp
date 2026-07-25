#include <mylib/mylib.hpp>

#include <iostream>


int
main() // NOLINT(bugprone-exception-escape)
{
  std::cout << mylib::compute_value(3.0) << '\n';
  return 0;
}
