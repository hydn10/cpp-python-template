set(_MYLIB_VCPKG_FEATURES)

if(MYLIB_BUILD_PYTHON)
    list(APPEND _MYLIB_VCPKG_FEATURES python)
endif()

list(APPEND VCPKG_MANIFEST_FEATURES ${_MYLIB_VCPKG_FEATURES})
list(REMOVE_DUPLICATES VCPKG_MANIFEST_FEATURES)

if(NOT DEFINED ENV{VCPKG_ROOT} OR "$ENV{VCPKG_ROOT}" STREQUAL "")
    message(FATAL_ERROR "VCPKG_ROOT must point to a vcpkg checkout.")
endif()

set(
    _MYLIB_VCPKG_TOOLCHAIN
    "$ENV{VCPKG_ROOT}/scripts/buildsystems/vcpkg.cmake")

if(NOT EXISTS "${_MYLIB_VCPKG_TOOLCHAIN}")
    message(
        FATAL_ERROR
        "vcpkg toolchain not found: ${_MYLIB_VCPKG_TOOLCHAIN}")
endif()

include("${_MYLIB_VCPKG_TOOLCHAIN}")

unset(_MYLIB_VCPKG_FEATURES)
unset(_MYLIB_VCPKG_TOOLCHAIN)
