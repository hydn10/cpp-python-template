find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG REQUIRED)

pybind11_add_module(
    _core
    "${PROJECT_SOURCE_DIR}/src/bindings/python/module.cpp"
)

target_link_libraries(_core PRIVATE mylib::mylib)

# When building with scikit-build-core, install the extension into the Python package.
if(DEFINED SKBUILD)
    install(
        TARGETS _core
        LIBRARY DESTINATION "${SKBUILD_PLATLIB_DIR}/mylib_apps"
        RUNTIME DESTINATION "${SKBUILD_PLATLIB_DIR}/mylib_apps"
    )
endif()

message(STATUS "Added Python module: _core")
