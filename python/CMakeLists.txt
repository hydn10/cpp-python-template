# Providers that predate prefixed FindPython artifacts may supply the native
# interpreter under the conventional unprefixed input name. Treat it as the
# build interpreter unless the caller supplied that role explicitly.
if(DEFINED Python_EXECUTABLE AND NOT DEFINED Python_BUILD_EXECUTABLE)
    set(Python_BUILD_EXECUTABLE "${Python_EXECUTABLE}")
endif()

# Discover the interpreter and destination artifacts independently in every
# build. In a native build they resolve to the same platform. In a cross build
# CMP0190 prevents the destination interpreter from being executed.
set(Python_ARTIFACTS_PREFIX "_BUILD")
find_package(Python 3.12 COMPONENTS Interpreter REQUIRED)
unset(Python_ARTIFACTS_PREFIX)

find_package(Python 3.12 COMPONENTS Development.Module REQUIRED)

if(
    NOT Python_BUILD_VERSION_MAJOR EQUAL Python_VERSION_MAJOR
    OR NOT Python_BUILD_VERSION_MINOR EQUAL Python_VERSION_MINOR
)
    message(
        FATAL_ERROR
        "Build Python ${Python_BUILD_VERSION} is incompatible with destination Python ${Python_VERSION}"
    )
endif()

# Nanobind 2.x consumes the unprefixed FindPython interpreter target and
# executable while using the destination Module target, headers, and SOABI.
add_executable(Python::Interpreter ALIAS Python_BUILD::Interpreter)
set(Python_EXECUTABLE "${Python_BUILD_EXECUTABLE}")

find_package(nanobind CONFIG REQUIRED)

nanobind_add_module(
    _core
    PROTECT_STACK
    NB_SUPPRESS_WARNINGS
    "${PROJECT_SOURCE_DIR}/lib/src/bindings/python/module.cpp"
)

target_link_libraries(_core PRIVATE "${PROJECT_NAME}::${PROJECT_NAME}")

stage_runtime_dlls(_core)

set(python_package_name mylib_tools)

# When building with scikit-build-core, install the extension into the shared
# support package used by the Python console apps.
if(DEFINED SKBUILD)
    install(
        TARGETS _core
        LIBRARY
            DESTINATION "${SKBUILD_PLATLIB_DIR}/${python_package_name}"
            COMPONENT python
        RUNTIME
            DESTINATION "${SKBUILD_PLATLIB_DIR}/${python_package_name}"
            COMPONENT python
    )
else()
    install(
        TARGETS _core
        LIBRARY DESTINATION "${CMAKE_INSTALL_LIBDIR}/${python_package_name}"
        RUNTIME DESTINATION "${CMAKE_INSTALL_LIBDIR}/${python_package_name}"
    )
endif()

message(
    STATUS
    "Python roles: build interpreter ${Python_BUILD_EXECUTABLE}; destination headers ${Python_INCLUDE_DIRS}; destination SOABI ${Python_SOABI}"
)

message(STATUS "Added Python module: _core")
