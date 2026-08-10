function(mylib_stage_runtime_dlls target_name)
    if(NOT WIN32)
        return()
    endif()

    add_custom_command(
        TARGET ${target_name}
        POST_BUILD
        COMMAND
            "${CMAKE_COMMAND}" -E copy -t $<TARGET_FILE_DIR:${target_name}>
            $<TARGET_RUNTIME_DLLS:${target_name}>
        COMMAND_EXPAND_LISTS
        VERBATIM
    )
endfunction()
