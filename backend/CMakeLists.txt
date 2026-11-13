cmake_minimum_required(VERSION 3.16)
project(dcsv_backend LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

option(BUILD_SERVER "Build máy chủ REST (cần Drogon)" ON)
option(BUILD_TESTS "Build unit test (GoogleTest)" OFF)

# ---- dcsv_core: logic thuần C++, không phụ thuộc Drogon, test được độc lập ----
add_library(dcsv_core
  src/utils/ArtifactCode.cc
)
target_include_directories(dcsv_core PUBLIC src)

# ---- dcsv_server: máy chủ REST dùng Drogon ----
if(BUILD_SERVER)
  find_package(Drogon CONFIG REQUIRED)
  file(GLOB_RECURSE SERVER_SOURCES CONFIGURE_DEPENDS
    src/main.cc
    src/controllers/*.cc
    src/services/*.cc
    src/repositories/*.cc
    src/models/*.cc
    src/filters/*.cc
    src/integrations/*.cc
    src/jobs/*.cc
  )
  add_executable(dcsv_server ${SERVER_SOURCES})
  target_link_libraries(dcsv_server PRIVATE dcsv_core Drogon::Drogon)
endif()

# ---- Unit test ----
if(BUILD_TESTS)
  enable_testing()
  find_package(GTest QUIET)
  if(NOT GTest_FOUND)
    include(FetchContent)
    FetchContent_Declare(googletest
      URL https://github.com/google/googletest/archive/refs/tags/v1.15.2.tar.gz)
    set(INSTALL_GTEST OFF CACHE BOOL "" FORCE)
    FetchContent_MakeAvailable(googletest)
  endif()
  file(GLOB TEST_SOURCES CONFIGURE_DEPENDS tests/*.cc)
  add_executable(dcsv_tests ${TEST_SOURCES})
  target_link_libraries(dcsv_tests PRIVATE dcsv_core GTest::gtest_main)
  include(GoogleTest)
  gtest_discover_tests(dcsv_tests)
endif()
