set(target_name "${PROJECT_NAME}")

find_package(Eigen3 CONFIG REQUIRED)

add_library(${target_name})
add_library("${PROJECT_NAME}::${PROJECT_NAME}" ALIAS ${target_name})

target_sources(
    ${target_name}
    PUBLIC
        FILE_SET HEADERS
            BASE_DIRS "${CMAKE_CURRENT_SOURCE_DIR}/include"
            FILES "${CMAKE_CURRENT_SOURCE_DIR}/include/mylib/mylib.hpp"
    PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/src/mylib.cpp"
)

target_compile_features(${target_name} PUBLIC cxx_std_17)
target_link_libraries(
    ${target_name}
    PRIVATE "$<BUILD_LOCAL_INTERFACE:Eigen3::Eigen>"
)

set_target_properties(
    ${target_name}
    PROPERTIES VERIFY_INTERFACE_HEADER_SETS ON EXPORT_NAME "${PROJECT_NAME}"
)

if(BUILD_SHARED_LIBS)
    set_target_properties(
        ${target_name}
        PROPERTIES WINDOWS_EXPORT_ALL_SYMBOLS ON
    )
endif()

install(
    TARGETS ${target_name}
    EXPORT "${PROJECT_NAME}-targets"
    FILE_SET HEADERS
)

message(STATUS "Added library: ${target_name}")
