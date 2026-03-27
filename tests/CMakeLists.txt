set(target_name mylib.tests.unit)

add_executable(${target_name})

target_sources(
    ${target_name}
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/cpp/test_compute_value.cpp"
)

target_compile_features(${target_name} PRIVATE cxx_std_23)
target_link_libraries(${target_name} PRIVATE mylib::mylib)

add_test(NAME compute_value COMMAND ${target_name})

message(STATUS "Added test: ${target_name}")
