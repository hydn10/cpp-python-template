set(target_name mylib)

add_library(${target_name})
add_library(mylib::mylib ALIAS ${target_name})

target_sources(
    ${target_name}
    PUBLIC
        FILE_SET HEADERS
        BASE_DIRS
            "${PROJECT_SOURCE_DIR}/include"
        FILES
            "${PROJECT_SOURCE_DIR}/include/mylib/mylib.hpp"
    PRIVATE
        "${PROJECT_SOURCE_DIR}/src/mylib.cpp"
)

target_compile_features(${target_name} PUBLIC cxx_std_17)

set_target_properties(
    ${target_name}
    PROPERTIES
        VERIFY_INTERFACE_HEADER_SETS ON
        EXPORT_NAME mylib
)

if(BUILD_SHARED_LIBS)
    set_target_properties(
        ${target_name}
        PROPERTIES
            WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

install(
    TARGETS ${target_name}
    EXPORT mylib-targets
    FILE_SET HEADERS
)

message(STATUS "Added library: ${target_name}")
