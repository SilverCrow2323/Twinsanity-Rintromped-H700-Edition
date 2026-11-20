# Cross-compile the complete Linux runner and NativeEE engine for muOS H700.
# Invoke inside a Debian multiarch sysroot/container with ARM64 development packages installed.
set(CMAKE_SYSTEM_NAME Linux)
set(CMAKE_SYSTEM_PROCESSOR aarch64)

set(CMAKE_C_COMPILER aarch64-linux-gnu-gcc)
set(CMAKE_CXX_COMPILER aarch64-linux-gnu-g++)
set(CMAKE_ASM_COMPILER aarch64-linux-gnu-gcc)

# CMake probes must not try to execute target binaries on the x86_64 build host.
set(CMAKE_TRY_COMPILE_TARGET_TYPE STATIC_LIBRARY)

# Debian multiarch puts target headers/libraries in /usr/include/aarch64-linux-gnu
# and /usr/lib/aarch64-linux-gnu. The image deliberately installs no amd64 SDL2,
# EGL/GLES or FFmpeg development packages, so BOTH does not resolve host GL libs.
set(CMAKE_LIBRARY_ARCHITECTURE aarch64-linux-gnu CACHE STRING "Target multiarch tuple")
set(CMAKE_FIND_ROOT_PATH_MODE_PROGRAM NEVER)
set(CMAKE_FIND_ROOT_PATH_MODE_LIBRARY BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_INCLUDE BOTH)
set(CMAKE_FIND_ROOT_PATH_MODE_PACKAGE BOTH)
