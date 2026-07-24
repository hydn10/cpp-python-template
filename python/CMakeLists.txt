find_package(Python COMPONENTS Interpreter Development.Module REQUIRED)
find_package(pybind11 CONFIG REQUIRED)

pybind11_add_module(
    _core
    "${PROJECT_SOURCE_DIR}/lib/src/bindings/python/module.cpp"
)

target_link_libraries(_core PRIVATE mylib::mylib)

mylib_stage_runtime_dlls(_core)

# When building with scikit-build-core, install the extension into the shared
# support package used by the Python console apps.
if(DEFINED SKBUILD)
    install(
        TARGETS _core
        LIBRARY DESTINATION "${SKBUILD_PLATLIB_DIR}/mylib_tools"
        RUNTIME DESTINATION "${SKBUILD_PLATLIB_DIR}/mylib_tools"
    )
endif()

message(STATUS "Added Python module: _core")
