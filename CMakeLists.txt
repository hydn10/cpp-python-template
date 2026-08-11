cmake_minimum_required(VERSION 4.3)

# Trigger configuration on file change.
configure_file(vcpkg.json vcpkg.json COPYONLY)

file(READ "${CMAKE_CURRENT_BINARY_DIR}/vcpkg.json" PROJECT_MANIFEST_JSON)
string(JSON PROJECT_NAME_FROM_JSON GET "${PROJECT_MANIFEST_JSON}" name)
string(JSON PROJECT_VERSION_FROM_JSON GET "${PROJECT_MANIFEST_JSON}" version)

set(MYLIB_BUILD_PYTHON_DEFAULT OFF)
option(
    MYLIB_BUILD_PYTHON
    "Build the Python extension module. Default: ${MYLIB_BUILD_PYTHON_DEFAULT}."
    "${MYLIB_BUILD_PYTHON_DEFAULT}"
)
mark_as_advanced(MYLIB_BUILD_PYTHON)

project(
    "${PROJECT_NAME_FROM_JSON}"
    LANGUAGES CXX
    VERSION "${PROJECT_VERSION_FROM_JSON}"
)

# The project does not use C++ modules. Disabling their dependency scanner also
# keeps compiler-specific module flags out of clang-tidy invocations.
set(CMAKE_CXX_SCAN_FOR_MODULES OFF)

include("${CMAKE_CURRENT_SOURCE_DIR}/cmake/windows-runtime.cmake")
include(GNUInstallDirs)

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

set(project_targets_export "${PROJECT_NAME}-targets")

install(PACKAGE_INFO "${PROJECT_NAME}" EXPORT "${project_targets_export}")
