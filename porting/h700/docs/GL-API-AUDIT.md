# Desktop GL to H700 GLES audit

The upstream Linux backend requests OpenGL 4.1 core and compiles GLSL 4.10. H700 work must use the firmware's actual EGL/OpenGL ES stack; similarly named functions are not automatically interchangeable.

| Upstream area | Desktop assumption | H700 action |
|---|---|---|
| engine/engine/platform/host/platform.h | Linux includes GL/glcorearb.h | Add explicit GLES header selection for H700; do not identify it as Vita |
| engine/engine/platform/sdl/gl_context.cpp | GL 4.1 core profile | Request ES 3.2 through SDL and inspect the created context |
| engine/engine/render/backends/gl/gl_vertex_stream.cpp | glMapBufferRange, explicit flush and sync objects | Gate by actual GLES version/extensions or add a safe buffer-subdata/orphan fallback |
| sampler/FBO/readback code | desktop sampler objects, blits and PBO/readback paths | Audit every API, format and extension before enabling |
| shaders | GLSL 4.10 core | Build and test ES shader variants; no blind version-string replacement |

The upstream Vita path is not the GLES solution: its platform and draw path are Vita/GXM-specific. It does not provide a drop-in H700 renderer.

Every call site and shader feature must be classified as GLES core, extension (runtime checked), safely emulatable, renderer algorithm change, or unused/excluded in the H700 build. A passing preflight context is not a playable port.
