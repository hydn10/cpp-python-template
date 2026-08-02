cmake_minimum_required(VERSION 3.27)

# Trigger configuration on file change.
configure_file(vcpkg.json vcpkg.json COPYONLY)

file(READ "${CMAKE_CURRENT_BINARY_DIR}/vcpkg.json" MYLIB_JSON_STRING)
string(JSON VERSION_FROM_JSON GET "${MYLIB_JSON_STRING}" version)

set(MYLIB_BUILD_PYTHON_DEFAULT OFF)
option(
    MYLIB_BUILD_PYTHON
    "Build the Python packaging extension module. Default: ${MYLIB_BUILD_PYTHON_DEFAULT}."
    "${MYLIB_BUILD_PYTHON_DEFAULT}"
)
mark_as_advanced(MYLIB_BUILD_PYTHON)

set(MYLIB_BUILD_APPS_DEFAULT "${PROJECT_IS_TOP_LEVEL}")
option(
    MYLIB_BUILD_APPS
    "Build the C++ applications. Default: ${MYLIB_BUILD_APPS_DEFAULT}."
    "${MYLIB_BUILD_APPS_DEFAULT}"
)

set(MYLIB_BUILD_EXAMPLES_DEFAULT "${PROJECT_IS_TOP_LEVEL}")
option(
    MYLIB_BUILD_EXAMPLES
    "Build the C++ examples. Default: ${MYLIB_BUILD_EXAMPLES_DEFAULT}."
    "${MYLIB_BUILD_EXAMPLES_DEFAULT}"
)

set(MYLIB_BUILD_TESTING_DEFAULT "${PROJECT_IS_TOP_LEVEL}")
option(
    MYLIB_BUILD_TESTING
    "Build the tests. Default: ${MYLIB_BUILD_TESTING_DEFAULT}."
    "${MYLIB_BUILD_TESTING_DEFAULT}"
)

project(mylib LANGUAGES CXX VERSION "${VERSION_FROM_JSON}")

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/mylib-windows-runtime.cmake")
include(CMakePackageConfigHelpers)
include(GNUInstallDirs)

add_subdirectory(lib)

if(MYLIB_BUILD_APPS)
    add_subdirectory(apps)
endif()

if(MYLIB_BUILD_EXAMPLES)
    add_subdirectory(examples)
endif()

if(MYLIB_BUILD_PYTHON)
    add_subdirectory(python)
endif()

if(MYLIB_BUILD_TESTING)
    enable_testing()
    add_subdirectory(tests)
endif()

install(
    EXPORT mylib-targets
    NAMESPACE mylib::
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib"
    FILE mylib-targets.cmake
)

configure_package_config_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/lib/mylib-config.cmake.in"
    "${CMAKE_CURRENT_BINARY_DIR}/lib/mylib-config.cmake"
    INSTALL_DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib"
    NO_SET_AND_CHECK_MACRO
)

write_basic_package_version_file(
    "${CMAKE_CURRENT_BINARY_DIR}/lib/mylib-version.cmake"
    COMPATIBILITY ExactVersion
)

install(
    FILES
        "${CMAKE_CURRENT_BINARY_DIR}/lib/mylib-config.cmake"
        "${CMAKE_CURRENT_BINARY_DIR}/lib/mylib-version.cmake"
    DESTINATION "${CMAKE_INSTALL_LIBDIR}/cmake/mylib"
)
