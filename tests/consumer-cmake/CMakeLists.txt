cmake_minimum_required(VERSION 3.26)

file(READ "${CMAKE_CURRENT_LIST_DIR}/../../vcpkg.json" PROJECT_MANIFEST_JSON)
string(JSON package_name GET "${PROJECT_MANIFEST_JSON}" name)

project("${package_name}_consumer_smoke" LANGUAGES CXX)

find_package("${package_name}" CONFIG REQUIRED)

set(target_name "${package_name}-consumer-smoke")

add_executable(${target_name})

target_sources(${target_name} PRIVATE "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp")

target_compile_features(${target_name} PRIVATE cxx_std_17)
target_link_libraries(${target_name} PRIVATE "${package_name}::${package_name}")

if(WIN32)
    add_custom_command(
        TARGET ${target_name}
        POST_BUILD
        COMMAND
            "${CMAKE_COMMAND}" -E copy -t $<TARGET_FILE_DIR:${target_name}>
            $<TARGET_RUNTIME_DLLS:${target_name}>
        COMMAND_EXPAND_LISTS
        VERBATIM
    )
endif()

enable_testing()
add_test(NAME "${package_name}-installed-consumer" COMMAND ${target_name})
