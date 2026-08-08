set(_MYLIB_VCPKG_FEATURES)

# Any additional MYLIB options used here must be defined before project(). Their
# defaults cannot use PROJECT_IS_TOP_LEVEL without a pre-project replacement.

# scikit-build-core supplies Python and nanobind from its isolated build
# environment. Direct CMake builds obtain them from vcpkg.
if(MYLIB_BUILD_PYTHON AND NOT DEFINED SKBUILD)
    list(APPEND _MYLIB_VCPKG_FEATURES python)
endif()

list(APPEND VCPKG_MANIFEST_FEATURES ${_MYLIB_VCPKG_FEATURES})
list(REMOVE_DUPLICATES VCPKG_MANIFEST_FEATURES)

if(NOT DEFINED ENV{VCPKG_ROOT} OR "$ENV{VCPKG_ROOT}" STREQUAL "")
    message(FATAL_ERROR "VCPKG_ROOT must point to a vcpkg checkout.")
endif()

set(_MYLIB_VCPKG_TOOLCHAIN "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")

if(NOT EXISTS "${_MYLIB_VCPKG_TOOLCHAIN}")
    message(FATAL_ERROR "vcpkg toolchain not found: ${_MYLIB_VCPKG_TOOLCHAIN}")
endif()

include("${_MYLIB_VCPKG_TOOLCHAIN}")

# vcpkg installs host dependencies under the host triplet, but its Python
# wrapper intentionally excludes the target Python executable from generic
# interpreter searches. Resolve the explicitly declared build-machine Python
# here so FindPython can keep its build and destination roles separate.
if(
    MYLIB_BUILD_PYTHON
    AND NOT DEFINED SKBUILD
    AND NOT DEFINED Python_BUILD_EXECUTABLE
)
    if(DEFINED VCPKG_HOST_TRIPLET AND NOT VCPKG_HOST_TRIPLET STREQUAL "")
        set(_MYLIB_VCPKG_BUILD_TRIPLET "${VCPKG_HOST_TRIPLET}")
    elseif(CMAKE_CROSSCOMPILING)
        message(
            FATAL_ERROR
            "A vcpkg cross build of the Python extension must set "
            "VCPKG_HOST_TRIPLET or provide Python_BUILD_EXECUTABLE explicitly."
        )
    else()
        # Native vcpkg builds deduplicate host and target dependencies into the
        # target triplet installation.
        set(_MYLIB_VCPKG_BUILD_TRIPLET "${VCPKG_TARGET_TRIPLET}")
    endif()

    set(_MYLIB_VCPKG_BUILD_PYTHON_DIR
        "${VCPKG_INSTALLED_DIR}/${_MYLIB_VCPKG_BUILD_TRIPLET}/tools/python3"
    )
    find_program(
        Python_BUILD_EXECUTABLE
        NAMES python3 python
        PATHS "${_MYLIB_VCPKG_BUILD_PYTHON_DIR}"
        NO_DEFAULT_PATH
    )

    if(NOT Python_BUILD_EXECUTABLE)
        message(
            FATAL_ERROR
            "The vcpkg python feature did not provide a build-machine interpreter under "
            "${_MYLIB_VCPKG_BUILD_PYTHON_DIR}."
        )
    endif()

    unset(_MYLIB_VCPKG_BUILD_PYTHON_DIR)
    unset(_MYLIB_VCPKG_BUILD_TRIPLET)
endif()

unset(_MYLIB_VCPKG_FEATURES)
unset(_MYLIB_VCPKG_TOOLCHAIN)
