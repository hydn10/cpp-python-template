cmake_minimum_required(VERSION 3.21)

project(mylib VERSION 0.1.0 LANGUAGES CXX)

include(GNUInstallDirs)

option(BUILD_EXAMPLES "Build C++ example program" ON)
option(BUILD_PYTHON "Build Python extension module" OFF)

# If building via scikit-build-core, enable Python extension by default
if(DEFINED SKBUILD)
  set(BUILD_PYTHON ON)
endif()

add_library(mylib STATIC
  src/mylib.cpp
)

target_include_directories(mylib
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:${CMAKE_INSTALL_INCLUDEDIR}>
)

target_compile_features(mylib PUBLIC cxx_std_17)

# Install the C++ library and headers (usable from other C++ projects)
install(TARGETS mylib
  EXPORT mylibTargets
  ARCHIVE DESTINATION ${CMAKE_INSTALL_LIBDIR}
  LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
  RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  INCLUDES DESTINATION ${CMAKE_INSTALL_INCLUDEDIR}
)
install(DIRECTORY include/ DESTINATION ${CMAKE_INSTALL_INCLUDEDIR})

# Generate and install a CMake package config so other CMake projects can find_package(mylib)
include(CMakePackageConfigHelpers)
write_basic_package_version_file(
  "${CMAKE_CURRENT_BINARY_DIR}/mylibConfigVersion.cmake"
  VERSION ${PROJECT_VERSION}
  COMPATIBILITY SameMajorVersion
)

export(EXPORT mylibTargets
  FILE "${CMAKE_CURRENT_BINARY_DIR}/mylibTargets.cmake"
  NAMESPACE mylib::
)

configure_package_config_file(
  "${CMAKE_CURRENT_SOURCE_DIR}/cmake/mylibConfig.cmake.in"
  "${CMAKE_CURRENT_BINARY_DIR}/mylibConfig.cmake"
  INSTALL_DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mylib
)

install(EXPORT mylibTargets
  FILE mylibTargets.cmake
  NAMESPACE mylib::
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mylib
)

install(FILES
  "${CMAKE_CURRENT_BINARY_DIR}/mylibConfig.cmake"
  "${CMAKE_CURRENT_BINARY_DIR}/mylibConfigVersion.cmake"
  DESTINATION ${CMAKE_INSTALL_LIBDIR}/cmake/mylib
)

# Optional: a small C++ example that links to the library
if(BUILD_EXAMPLES)
  add_executable(mylib_example examples/cpp_example.cpp)
  target_link_libraries(mylib_example PRIVATE mylib)
  target_compile_features(mylib_example PRIVATE cxx_std_17)

  # Install the example program when examples are enabled
  install(TARGETS mylib_example
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
  )
endif()

# Python binding using pybind11 (built when BUILD_PYTHON=ON, default under scikit-build)
if(BUILD_PYTHON)
  find_package(pybind11 CONFIG REQUIRED)
  pybind11_add_module(_core MODULE
    src/bindings/python/module.cpp
  )
  target_link_libraries(_core PRIVATE mylib)
  target_compile_features(_core PRIVATE cxx_std_17)

  # When building with scikit-build-core, install the extension into the Python package
  if(DEFINED SKBUILD)
    # Install to the platform-specific package dir, inside the mylib_apps package
    install(TARGETS _core
      LIBRARY DESTINATION ${SKBUILD_PLATLIB_DIR}/mylib_apps
      RUNTIME DESTINATION ${SKBUILD_PLATLIB_DIR}/mylib_apps
    )
  endif()
endif()
