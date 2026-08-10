function(add_project_app app_name)
    set(target_name "${PROJECT_NAME}.apps.${app_name}")

    add_executable(${target_name})

    target_sources(${target_name} PRIVATE ${ARGN})

    target_compile_features(${target_name} PRIVATE cxx_std_23)
    target_link_libraries(
        ${target_name}
        PRIVATE "${PROJECT_NAME}::${PROJECT_NAME}"
    )

    set_target_properties(
        ${target_name}
        PROPERTIES OUTPUT_NAME "${PROJECT_NAME}-${app_name}"
    )

    stage_runtime_dlls(${target_name})

    install(
        TARGETS ${target_name}
        RUNTIME DESTINATION "${CMAKE_INSTALL_BINDIR}"
    )

    message(STATUS "Added application: ${target_name}")
endfunction()

add_project_app(
    sample
    "${CMAKE_CURRENT_SOURCE_DIR}/sample.cpp"
)
