cmake_minimum_required(VERSION 3.26)

project(mylib_consumer_smoke LANGUAGES CXX)

find_package(mylib CONFIG REQUIRED)

add_executable(mylib-consumer-smoke)

target_sources(
    mylib-consumer-smoke
    PRIVATE
        "${CMAKE_CURRENT_SOURCE_DIR}/main.cpp"
)

target_compile_features(mylib-consumer-smoke PRIVATE cxx_std_17)
target_link_libraries(mylib-consumer-smoke PRIVATE mylib::mylib)

get_target_property(mylib_imported_type mylib::mylib TYPE)
if(WIN32 AND mylib_imported_type STREQUAL "SHARED_LIBRARY")
    add_custom_command(
        TARGET mylib-consumer-smoke
        POST_BUILD
        COMMAND
            "${CMAKE_COMMAND}" -E copy_if_different
            $<TARGET_RUNTIME_DLLS:mylib-consumer-smoke>
            $<TARGET_FILE_DIR:mylib-consumer-smoke>
        COMMAND_EXPAND_LISTS
    )
endif()

enable_testing()
add_test(NAME mylib-installed-consumer COMMAND mylib-consumer-smoke)
