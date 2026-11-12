# Desktop GL to H700 GLES audit

This is a source-level compatibility audit. It does not claim that the H700 renderer is implemented or that any game scene runs on-device.

## Confirmed source assumptions

| Source | Current assumption | H700 consequence |
|---|---|---|
| Root CMakeLists.txt | Non-Vita Linux finds SDL2 and desktop OpenGL | An AArch64 target still follows the desktop GL dependency unless a separate target is added |
| engine/cmake/OpenGlDependency.cmake | Uses OpenGL::GL outside the Vita lane | Add an explicit EGL/GLES dependency path; do not silently replace the desktop dependency |
| engine/engine/platform/host/platform.h | Linux includes GL/glcorearb.h | H700 needs GLES headers and a separate compile definition |
| engine/engine/platform/sdl/gl_context.cpp | Requests OpenGL 4.1 core through SDL | A handheld profile must request an ES context and record the actual returned version |
| engine/engine/render/backends/gl/CMakeLists.txt | Builds the common GL renderer against OpenGL::GL | The target is not currently an H700 GLES renderer |
| engine/engine/render/backends/gl/gl_shader_sources.cpp | Shader strings use #version 410 core | Build and test GLSL ES variants; changing only the version string is insufficient |
| engine/engine/render/backends/gl/gl_vertex_stream.cpp | Uses mapped buffers, explicit flush and sync objects | Check GLES version/extensions and provide a tested fallback where required |

## Shader-specific blocker

The PS2 S/T/Q shader path uses the GLSL interpolation qualifier noperspective. The Khronos GLSL ES 3.20 core specification lists smooth and flat as core interpolation qualifiers; noperspective is not in that core list.

The existing shader source comments that gl_Position.w is 1.0 in this path, so smooth interpolation may be equivalent for those vertices. That is a hypothesis to prove with frame/image comparisons, not permission to remove the qualifier globally.

References:
- Khronos GLSL ES 3.20 specification: https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html
- Arm Mali-G31 product page: https://support.arm.com/compute-ip/mali-g31
- Allwinner H700 brief: https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf

## API work still required

Classify every used GL call, enum, format and extension in the inventory before implementation. In particular, inspect:

- glMapBufferRange, explicit flush and sync/fence handling.
- Sampler objects and texture storage/update paths.
- Framebuffer/renderbuffer formats, depth/stencil attachments and blits.
- Pixel-store row length, texture-level queries and readback/PBO paths.
- Timer queries and optional anisotropic filtering.
- Shader precision declarations, interpolation semantics and any desktop-only GLSL features.

For each item record one disposition: GLES 3.2 core, runtime extension, safe fallback, renderer algorithm change, or not used by the H700 build.

## Why the Vita path is not reusable

The Vita build uses Vita-specific startup and vitaGL over Sony GXM. This is a separate platform path, not a generic GLES 3.2 implementation for Mali-G31.

## Preflight evidence boundary

The current H700 package contains:
- an EGL/GLES pbuffer probe;
- an SDL2 window probe that asks for an ES 3.2 context and swaps colour frames;
- a muOS device/environment inventory.

These tests determine whether the firmware can initialise EGL/GLES and SDL presentation. They do not compile the game's renderer, exercise its shaders, create the engine's render targets or enter gameplay.

## Implementation order

1. Collect the real device reports and record SDL video driver, EGL vendor, GLES renderer/version and extensions.
2. Add an explicit H700 build profile; never infer it only from the AArch64 CPU architecture.
3. Build a minimal GLES shader and render-target prototype.
4. Compare output with desktop references for title, UI, texture formats, transparency, depth, shadows and copies.
5. Add buffer-streaming and synchronisation fallbacks based on measured extensions.
6. Integrate input, audio, disc streaming and muOS packaging only after the renderer's first scene is stable.

A successful probe is not a playable-port claim.
