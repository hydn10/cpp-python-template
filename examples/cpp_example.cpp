#include <mylib/mylib.hpp>

#include <cstdio>
#include <exception>
#include <print>


int
main()
try
{
  try
  {
    double const xmin = -2.0;
    double const xmax = 2.0;

    auto const values = mylib::compute_values(xmin, xmax, 5);

    std::print(stdout, "compute_values({:g}, {:g}, 5) =", xmin, xmax);

    for (double const value : values)
    {
      std::print(stdout, " {:g}", value);
    }
    std::print(stdout, "\n");

    return 0;
  }
  catch (std::exception const &exception)
  {
    std::println(stderr, "example failed: {}", exception.what());
  }
  catch (...)
  {
    std::println(stderr, "example failed with an unknown exception");
  }

  return 1;
}
catch (...)
{
  return 2;
}
