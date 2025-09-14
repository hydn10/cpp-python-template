#include <iostream>

#include "mylib/mylib.hpp"

int main() {
  double x = 3.0;
  std::cout << "compute_value(" << x << ") = " << mylib::compute_value(x) << "\n";
  return 0;
}

