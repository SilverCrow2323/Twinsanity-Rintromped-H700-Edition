cmake_minimum_required(VERSION 3.21)
project(TwinsanityH700GlesCompile LANGUAGES CXX)

# Compile-only gate for the real engine GL backend against the target's GLES API.
# It deliberately does not link a game binary or claim renderer/runtime success.
get_filename_component(TE_ROOT "${CMAKE_CURRENT_LIST_DIR}/../../.." ABSOLUTE)

find_path(TE_GLES_INCLUDE_DIR NAMES GLES3/gl32.h REQUIRED)
find_path(TE_SDL2_INCLUDE_DIR NAMES SDL.h PATH_SUFFIXES SDL2 REQUIRED)

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
    "${TE_ROOT}"
    "${TE_GLES_INCLUDE_DIR}"
    "${TE_SDL2_INCLUDE_DIR}"
)
target_compile_definitions(h700_sdl_gles_compile PRIVATE PS2R_USE_GLES=1)
target_compile_options(h700_sdl_gles_compile PRIVATE -Wall -Wextra -Werror)

add_custom_target(h700_gles_compile_check DEPENDS
    h700_gles_renderer_compile
    h700_sdl_gles_compile
)
