# H700 renderer audit

## Purpose

Record the real renderer and platform dependencies before creating an H700 build target. This is a source audit, not a claim that the game has been ported or tested on an H700 device.

## Current desktop graphics path

| Area | Current implementation | H700 implication |
|---|---|---|
| Build dependency | Root `CMakeLists.txt` finds SDL2 and desktop `OpenGL::GL` for non-Vita builds | A CPU-only AArch64 build still links the desktop GL path |
| Renderer target | `engine/engine/render/backends/gl/CMakeLists.txt` builds `ps2r_render_gl` against `OpenGL::GL` and describes it as OpenGL 4.1 core | No GLES/Vulkan renderer target is defined here |
| Window/context | `engine/engine/platform/sdl/gl_context.cpp` requests OpenGL 4.1, core profile and forward compatibility through SDL | The H700 target needs a separately selected context profile and a verified SDL/EGL path |
| Shader language | `engine/engine/render/backends/gl/gl_shader_sources.cpp` contains multiple `#version 410 core` programs | Shaders need a deliberate GLES variant or a translation/compatibility layer |
| Host GL header | `engine/engine/platform/host/platform.h` selects `GL/glcorearb.h` for Linux | H700 needs the GLES header and function/library contract, not the desktop Linux GL header |
| Link dependency | `engine/cmake/OpenGlDependency.cmake` uses `find_package(OpenGL)` outside the Vita lane | A GLES link target must be introduced without changing desktop link behaviour |

The desktop SDL target is `ps2r_platform_sdl`. Its CMake definition links SDL2 and OpenGL and currently builds `window.cpp` plus `gl_context.cpp`.

## Shader compatibility finding

The source shader strings use `#version 410 core`. They also use the `noperspective` interpolation qualifier for the PS2 S/T/Q coordinates. The current vertex shader comments explain that `gl_Position.w` is 1.0 in that path, so ordinary perspective interpolation may be equivalent there; nevertheless, this must be proved by the existing frame/image judges before changing the qualifier.

The Khronos GLSL ES 3.20 specification lists `smooth` and `flat` as its core interpolation qualifiers; `noperspective` is not part of that core list. Do not simply replace the shader version or delete the qualifier without checking all shader variants and their output.

- [Khronos GLSL ES 3.20 specification — interpolation qualifiers](https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html)
- [Arm Mali-G31 product page](https://support.arm.com/compute-ip/mali-g31)

## API review still required

The existing GL backend calls a wide range of functions. The first source pass identified, among others:

- VAO/VBO creation and vertex attribute binding.
- Sampler objects and texture upload/update paths.
- Framebuffers, renderbuffers, depth/stencil attachments and readback.
- Texture-level queries and pixel-store row-length state.
- Extension enumeration and optional anisotropic filtering.
- GPU timer and synchronisation code in separate renderer modules.

Each call must be classified as GLES 3.2 core, extension-backed, desktop-only or replaceable. The list above is a starting inventory, not a complete API compatibility report.

## Vita is not the H700 backend

The Vita build has its own conditional path through vitaGL over Sony GXM. The source describes that implementation as an ES 2-class compatibility layer and uses Vita-specific memory pools and startup logic. It is useful historical evidence that the engine can have platform-specific graphics setup, but it does not prove that the desktop renderer already works on Mali-G31.

## Recommended next implementation sequence

1. Add an explicit target/profile option; do not infer H700 from `CMAKE_SYSTEM_PROCESSOR=aarch64`.
2. Add a small SDL/EGL context probe that logs SDL version, GL vendor, renderer, version and extensions on the device.
3. Build a GLES shader prototype with the minimum scanout shader and a known test texture.
4. Convert each shader family in stages and compare pixel captures against the desktop reference.
5. Audit FBO formats, depth/stencil behaviour, texture queries, buffer streaming and timer APIs.
6. Only after the graphics probe works, integrate the existing SDL input and audio services with the actual muOS runtime.
7. Measure the H700 device before setting resolution, scaling, filtering or threading defaults.

## Acceptance gates

- Desktop OpenGL 4.1 build remains unchanged.
- The H700 profile selects GLES explicitly and fails early with a useful message when the context/API is unavailable.
- Shader image tests pass for the title, menus, movies, UI, transparency, shadows and render-target copies.
- Input, audio, disc streaming, saves, exit and repeated cold launches pass on the actual H700 device.
- Logs record device, firmware, renderer/version, build commit and test results.

Until these gates pass, the H700 target remains experimental and unvalidated.
