cmake_minimum_required(VERSION 3.21)
project(TwinsanityH700GlesCompile LANGUAGES CXX)

# Compile-only gate for the real engine GL backend against the target's GLES API.
# It deliberately does not link a game binary or claim renderer/runtime success.
get_filename_component(TE_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

find_path(TE_GLES_INCLUDE_DIR NAMES GLES3/gl32.h REQUIRED)
find_path(TE_EGL_INCLUDE_DIR NAMES EGL/egl.h REQUIRED)
find_path(TE_SDL2_INCLUDE_DIR NAMES SDL.h PATH_SUFFIXES SDL2 REQUIRED)
# The target SDL2 package stores its generated config in the AArch64 multiarch include tree.
find_path(TE_SDL2_TARGET_CONFIG_INCLUDE_DIR NAMES SDL2/_real_SDL_config.h
    PATHS /usr/include/aarch64-linux-gnu NO_DEFAULT_PATH REQUIRED)
find_library(TE_GLES_LIBRARY NAMES GLESv2 REQUIRED)
find_library(TE_EGL_LIBRARY NAMES EGL REQUIRED)

set(TE_GLES_RENDER_SOURCES
    "${TE_ROOT}/engine/engine/render/backends/gl/blend_ff_map.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/cd_copy_policy.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_device.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_draw_executor.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_fill_census.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_gpu_lifetime.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_gpu_timers.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_movie.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_shader_library.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_shader_sources.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_state_cache.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_texture_pool.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_uniform_cache.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_vertex_stream.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/vertex_convert.cpp"
)

add_library(h700_gles_renderer_compile OBJECT ${TE_GLES_RENDER_SOURCES})
target_compile_features(h700_gles_renderer_compile PRIVATE cxx_std_17)
target_include_directories(h700_gles_renderer_compile PRIVATE
    "${TE_ROOT}/engine"
    "${TE_ROOT}"
    "${TE_GLES_INCLUDE_DIR}"
)
target_compile_definitions(h700_gles_renderer_compile PRIVATE PS2R_USE_GLES=1)
target_compile_options(h700_gles_renderer_compile PRIVATE -Wall -Wextra -Werror)

add_library(h700_sdl_gles_compile OBJECT
    "${TE_ROOT}/engine/engine/platform/sdl/window.cpp"
    "${TE_ROOT}/engine/engine/platform/sdl/gl_context.cpp"
)
target_compile_features(h700_sdl_gles_compile PRIVATE cxx_std_17)
target_include_directories(h700_sdl_gles_compile PRIVATE
    "${TE_ROOT}/engine"
    "${TE_ROOT}"
    "${TE_GLES_INCLUDE_DIR}"
    "${TE_SDL2_TARGET_CONFIG_INCLUDE_DIR}"
    "${TE_SDL2_INCLUDE_DIR}"
)
target_compile_definitions(h700_sdl_gles_compile PRIVATE PS2R_USE_GLES=1)
target_compile_options(h700_sdl_gles_compile PRIVATE -Wall -Wextra -Werror)

add_custom_target(h700_gles_compile_check DEPENDS
    h700_gles_renderer_compile
    h700_sdl_gles_compile
)

# Runtime shader smoke: creates a headless EGL/GLES 3.2 context and calls the
# production NativeEE GlShaderLibrary::Build(). No game binary or SDL window.
add_executable(h700_gles_shader_smoke
    "${CMAKE_CURRENT_LIST_DIR}/shader_smoke.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_shader_library.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_shader_sources.cpp"
    "${TE_ROOT}/engine/engine/render/backends/gl/gl_uniform_cache.cpp"
)
target_compile_features(h700_gles_shader_smoke PRIVATE cxx_std_17)
target_include_directories(h700_gles_shader_smoke PRIVATE
    "${TE_ROOT}/engine"
    "${TE_ROOT}"
    "${TE_GLES_INCLUDE_DIR}"
    "${TE_EGL_INCLUDE_DIR}"
)
target_compile_definitions(h700_gles_shader_smoke PRIVATE PS2R_USE_GLES=1)
target_compile_options(h700_gles_shader_smoke PRIVATE
    -Wall -Wextra -Werror -ffunction-sections -fdata-sections
)
target_link_libraries(h700_gles_shader_smoke PRIVATE
    "${TE_EGL_LIBRARY}"
    "${TE_GLES_LIBRARY}"
)
if(UNIX AND NOT APPLE)
    target_link_options(h700_gles_shader_smoke PRIVATE -Wl,--gc-sections)
endif()

add_custom_target(h700_gles_shader_smoke_check DEPENDS h700_gles_shader_smoke)
