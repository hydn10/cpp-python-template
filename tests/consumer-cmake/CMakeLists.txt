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
