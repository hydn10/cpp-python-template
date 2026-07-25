#include <mylib/mylib.hpp>

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
    double const xmin = -2.0;
    double const xmax = 2.0;

    auto const values = mylib::compute_values(xmin, xmax, 5);

    std::print("compute_values({:g}, {:g}, 5) =", xmin, xmax);

    for (double const value : values)
    {
      std::print(" {:g}", value);
    }
    std::print("\n");

    return 0;
  }
  catch (std::exception const &exception)
  {
    std::println(error_stream, "application failed: {}", exception.what());
  }
  catch (...)
  {
    std::println(error_stream, "application failed with an unknown exception");
  }

  return 1;
}
catch (...)
{
  return 2;
}
