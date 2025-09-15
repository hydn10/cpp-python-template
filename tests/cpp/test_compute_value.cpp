// Minimal unit test without external framework: returns non-zero on failure
#include "mylib/mylib.hpp"
#include <cmath>
#include <iostream>

int main() {
  const double x = 3.0;
  const double expected = x * x + 1.0; // 10.0
  const double got = mylib::compute_value(x);
  if (std::abs(got - expected) > 1e-12) {
    std::cerr << "compute_value(" << x << ") expected " << expected
              << ", got " << got << "\n";
    return 1;
  }
  return 0;
}

