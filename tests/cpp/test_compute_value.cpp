#include <mylib/mylib.hpp>

#include <cmath>
#include <cstdio>
#include <exception>
#include <print>


int
main()
try
{
  std::FILE *const error_stream = stderr;

  try
  {
    double const x = 3.0;
    double const expected = x * x + 1.0;
    double const got = mylib::compute_value(x);

    if (std::abs(got - expected) > 1e-12)
    {
      std::println(error_stream, "compute_value({:g}) expected {:g}, got {:g}", x, expected, got);
      return 1;
    }

    auto const values = mylib::compute_values(-1.0, 1.0, 3);
    if (values.size() != 3u)
    {
      std::println(error_stream, "compute_values returned {} samples, expected 3", values.size());
      return 1;
    }

    if (std::abs(values.at(0) - 2.0) > 1e-12 || std::abs(values.at(1) - 1.0) > 1e-12 ||
        std::abs(values.at(2) - 2.0) > 1e-12)
    {
      std::println(error_stream, "compute_values returned unexpected samples");
      return 1;
    }

    auto const single_value = mylib::compute_values(2.0, 5.0, 1);
    if (single_value.size() != 1u || std::abs(single_value.front() - 5.0) > 1e-12)
    {
      std::println(error_stream, "compute_values single-point case failed");
      return 1;
    }

    return 0;
  }
  catch (std::exception const &exception)
  {
    std::println(error_stream, "test failed: {}", exception.what());
  }
  catch (...)
  {
    std::println(error_stream, "test failed with an unknown exception");
  }

  return 1;
}
catch (...)
{
  return 2;
}
