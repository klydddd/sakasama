cmake_minimum_required(VERSION 3.22.1)

project(sakasama_vlm)

# Disable building standalone tests, executables, and tools in llama.cpp
set(LLAMA_BUILD_TESTS OFF CACHE BOOL "Build tests" FORCE)
set(LLAMA_BUILD_EXAMPLES OFF CACHE BOOL "Build examples" FORCE)
set(LLAMA_BUILD_SERVER OFF CACHE BOOL "Build server" FORCE)
set(LLAMA_BUILD_COMMON FALSE CACHE BOOL "Build common" FORCE)

# We need the multimodal library
set(LLAMA_BUILD_MTMD ON CACHE BOOL "Build multimodal library" FORCE)

# Disable llamafile optimizations to prevent ARM NEON float16 compiler errors (sgemm.cpp)
set(GGML_LLAMAFILE OFF CACHE BOOL "Disable llamafile" FORCE)

# Ensure it builds as shared libraries for Android
set(BUILD_SHARED_LIBS ON CACHE BOOL "Build shared libs" FORCE)

# Add the cloned llama.cpp repository
add_subdirectory(src/main/cpp/llama.cpp)

# Manually add the mtmd (multimodal) library since tools are disabled
add_subdirectory(src/main/cpp/llama.cpp/tools/mtmd)

# Define our JNI Bridge
add_library(sakasama_vlm SHARED
    src/main/cpp/got_ocr_bridge.cpp
)

# Includes
target_include_directories(sakasama_vlm PRIVATE
    src/main/cpp/llama.cpp/include
    src/main/cpp/llama.cpp/ggml/include
    src/main/cpp/llama.cpp/tools/mtmd
    src/main/cpp/llama.cpp/common
)

# Link against the necessary llama.cpp targets, JNI, and Android logging
target_link_libraries(sakasama_vlm PRIVATE
    mtmd
    llama
    ggml
    android
    log
)

# Standard Android NDK flags
target_compile_options(sakasama_vlm PRIVATE
    -Wall
    -fexceptions
    -frtti
    -std=c++17
)
