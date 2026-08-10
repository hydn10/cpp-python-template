function(add_project_example example_name)
    set(target_name "${PROJECT_NAME}.examples.${example_name}")

    add_executable(${target_name})

    target_sources(${target_name} PRIVATE ${ARGN})

    target_compile_features(${target_name} PRIVATE cxx_std_17)
    target_link_libraries(
        ${target_name}
        PRIVATE "${PROJECT_NAME}::${PROJECT_NAME}"
    )

    set_target_properties(
        ${target_name}
        PROPERTIES OUTPUT_NAME "${PROJECT_NAME}-${example_name}-example"
    )

    stage_runtime_dlls(${target_name})

    message(STATUS "Added example: ${target_name}")
endfunction()

add_project_example(
    basic-usage
    "${CMAKE_CURRENT_SOURCE_DIR}/basic_usage.cpp"
)
