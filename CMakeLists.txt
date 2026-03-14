cmake_minimum_required(VERSION 3.22)

project(clap_ambient LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 20)
set(CMAKE_POSITION_INDEPENDENT_CODE ON)

set(CLAP_WRAPPER_DOWNLOAD_DEPENDENCIES FALSE CACHE BOOL "Download Dependencies")
set(VST3_SDK_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/libs/vst3sdk)
set(CLAP_SDK_ROOT ${CMAKE_CURRENT_SOURCE_DIR}/libs/clap)
set(CLAP_VST3_TUID_STRING "camb")

FILE(GLOB odin_object_files ${ODIN_OBJ_DIR}/*.obj)

add_library(plugin_entry STATIC Source/plugin_entry.cpp ${odin_object_files})
target_link_libraries(plugin_entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/build/${PUGL_LIBNAME}
    ${CMAKE_CURRENT_SOURCE_DIR}/build/${IMGUI_LIBNAME}
)

if(WIN32)
    target_link_libraries(plugin_entry PRIVATE 
        Dwmapi.lib
        user32.lib
        opengl32.lib
    )
    
else() 
    # tester sur linux
    target_link_libraries(plugin_entry PRIVATE Gl) 
endif()


add_compile_options(-D_DLL -mavx -fno-math-errno -Wall -Wextra
                    -Wno-pragma-pack
                    -Wno-unused-parameter
                    -Wno-unused-function
                    -Wno-missing-field-initializers
                    -Wno-deprecated-declarations
                    -Wno-format
                    -Wno-nontrivial-memcall
                    -Wno-implicit-const-int-float-conversion
                    -Wno-microsoft-enum-value)

add_subdirectory(${CMAKE_CURRENT_SOURCE_DIR}/libs/clap-wrapper)
set(VST3_TARGET ${PROJECT_NAME}_vst3)

make_clapfirst_plugins(
    TARGET_NAME             ${PROJECT_NAME}
    IMPL_TARGET             plugin_entry
    OUTPUT_NAME             ${PROJECT_NAME}
    ENTRY_SOURCE            Source/plugin_entry.cpp
    COPY_AFTER_BUILD        FALSE
    WINDOWS_FOLDER_VST3     FALSE
    PLUGIN_FORMATS          CLAP VST3
)
