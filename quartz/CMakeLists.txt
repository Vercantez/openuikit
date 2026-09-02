cmake_minimum_required(VERSION 3.16)
project(quartz LANGUAGES C CXX OBJCXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_OBJCXX_STANDARD 17)

if(NOT CMAKE_BUILD_TYPE)
  set(CMAKE_BUILD_TYPE Release)
endif()

add_compile_options(-Wall -Wextra -Wno-unused-parameter -Wno-unused-function)

file(GLOB QZ_PKG_SOURCES CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/src/pkg_*.cpp)
add_library(quartz STATIC
  src/qz_math.cpp
  src/qz_path.cpp
  src/qz_stroke.cpp
  src/qz_raster.cpp
  src/qz_context.cpp
  src/qz_image.cpp
  src/qz_transform3d.cpp
  src/qz_layer.cpp
  ${QZ_PKG_SOURCES}
)
target_include_directories(quartz
  PUBLIC ${CMAKE_SOURCE_DIR}/include
  PRIVATE ${CMAKE_SOURCE_DIR}/src ${CMAKE_SOURCE_DIR}/third_party
)

if(APPLE)
  file(GLOB QZ_SCENE_EXTRAS CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/harness/scenes_*.cpp)
  list(FILTER QZ_SCENE_EXTRAS EXCLUDE REGEX "scenes_ca\\.cpp$")
  add_executable(qzcompare
    harness/main.cpp
    harness/registry.cpp
    harness/apple_backend.cpp
    harness/qz_backend.cpp
    harness/scenes.cpp
    harness/scenes_ca.cpp
    harness/qz_layer_backend.cpp
    harness/apple_layer.mm
    ${QZ_SCENE_EXTRAS}
  )
  set_source_files_properties(harness/apple_layer.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")
  target_include_directories(qzcompare PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/harness
    ${CMAKE_SOURCE_DIR}/third_party
  )
  target_link_libraries(qzcompare PRIVATE quartz
    "-framework CoreGraphics"
    "-framework CoreFoundation"
    "-framework ImageIO"
    "-framework QuartzCore"
    "-framework Foundation")

  add_executable(QuartzDemo MACOSX_BUNDLE
    demo/main.mm
    harness/registry.cpp
    harness/apple_backend.cpp
    harness/qz_backend.cpp
    harness/scenes.cpp
    harness/scenes_ca.cpp
    harness/qz_layer_backend.cpp
    harness/apple_layer.mm
    ${QZ_SCENE_EXTRAS}
  )
  set_source_files_properties(demo/main.mm harness/apple_layer.mm PROPERTIES COMPILE_FLAGS "-fobjc-arc")
  target_include_directories(QuartzDemo PRIVATE
    ${CMAKE_SOURCE_DIR}/include
    ${CMAKE_SOURCE_DIR}/harness
    ${CMAKE_SOURCE_DIR}/third_party)
  target_link_libraries(QuartzDemo PRIVATE quartz
    "-framework Cocoa"
    "-framework CoreGraphics"
    "-framework CoreFoundation"
    "-framework ImageIO"
    "-framework Foundation"
    "-framework QuartzCore")
  set_target_properties(QuartzDemo PROPERTIES
    MACOSX_BUNDLE TRUE
    MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/demo/Info.plist
    MACOSX_BUNDLE_BUNDLE_NAME "Quartz Inspector"
    MACOSX_BUNDLE_GUI_IDENTIFIER ai.x.quartz.demo)

  file(GLOB QZ_TESTS CONFIGURE_DEPENDS ${CMAKE_SOURCE_DIR}/tests/test_*.mm)
  foreach(test_src ${QZ_TESTS})
    get_filename_component(test_name ${test_src} NAME_WE)
    add_executable(${test_name} ${test_src})
    set_source_files_properties(${test_src} PROPERTIES COMPILE_FLAGS "-fobjc-arc")
    target_include_directories(${test_name} PRIVATE
      ${CMAKE_SOURCE_DIR}/include ${CMAKE_SOURCE_DIR}/tests)
    target_link_libraries(${test_name} PRIVATE quartz
      "-framework Foundation" "-framework CoreGraphics" "-framework QuartzCore"
      "-framework CoreText" "-framework ApplicationServices")
  endforeach()
endif()
