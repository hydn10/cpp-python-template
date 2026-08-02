function(add_mylib_example example_name)
    set(target_name "mylib.examples.${example_name}")

    add_executable(${target_name})

    target_sources(${target_name} PRIVATE ${ARGN})

    target_compile_features(${target_name} PRIVATE cxx_std_17)
    target_link_libraries(${target_name} PRIVATE mylib::mylib)

    set_target_properties(
        ${target_name}
        PROPERTIES OUTPUT_NAME "mylib-${example_name}-example"
    )

    mylib_stage_runtime_dlls(${target_name})

    message(STATUS "Added example: ${target_name}")
endfunction()

add_mylib_example(
    basic-usage
    "${CMAKE_CURRENT_SOURCE_DIR}/basic_usage.cpp"
)
