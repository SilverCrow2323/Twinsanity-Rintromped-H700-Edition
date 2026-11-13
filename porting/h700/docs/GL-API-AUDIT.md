# Desktop GL → H700 GLES audit

> [!NOTE]
> This is a source-level compatibility record. The physical H700 device has passed the graphics preflight, but the NativeEE renderer and gameplay remain unvalidated.

## Confirmed platform differences

| Source area | Desktop path | H700 path |
|---|---|---|
| Root CMakeLists.txt | OpenGL::GL desktop dependency | Explicit PS2R_GLES profile; forwarded into NativeEE ExternalProject |
| engine/cmake/OpenGlDependency.cmake | FindOpenGL / platform library | GLES3 headers and imported GLESv2 target |
| engine/platform/host/platform.h | GL/glcorearb.h | GLES3/gl32.h |
| engine/platform/sdl/gl_context.cpp | OpenGL 4.1 core | SDL ES 3.2 request and runtime version gate |
| GL shader source | GLSL 410 core | Audited GLSL ES 320 conversion |
| Uniform updates | glProgramUniform* | Bind target program, use glUniform*, restore |
| Depth clear | glClearDepth | glClearDepthf |
| Mip-level dimensions | glGetTexLevelParameteriv | Derive from base dimensions and mip index |
| Depth-only FBO | glDrawBuffer(GL_NONE) | glDrawBuffers(1, { GL_NONE }) |
| Vertex ring buffer | Unsynchronised desktop map flag | GLES write + explicit-flush flags |

## Physical device evidence · 12 November 2026

| Test | Result |
|---|---|
| EGL | 1.4 · ARM · Bifrost r20p0 |
| GPU | ARM Mali-G31 |
| OpenGL ES / GLSL ES | 3.2 / 3.20 |
| SDL video driver | mali |
| SDL window and context | Created |
| Presentation | Six visible colour frames |
| Framebuffer | 640×480p-59 |

The device also advertises GL_OES_mapbuffer, GL_EXT_buffer_storage, GL_OES_vertex_array_object, GL_EXT_texture_storage, ASTC families and GL_EXT_disjoint_timer_query. Extension presence is not proof that an engine feature has been integrated correctly.

## Shader-specific decision

The PS2 S/T/Q shader path declares noperspective on v_texcoord. GLSL ES 3.20 does not define noperspective as a core interpolation qualifier. The audited PS2 vertex path sets gl_Position.w = 1.0, making smooth interpolation screen-linear in that specific path.

The H700 conversion removes the qualifier only from that named varying. The source guard checks every embedded shader block. Visual equivalence still needs to be proven with actual NativeEE render captures.

## Remaining validation

- Compile all renderer translation units with GLES 3.2 headers for AArch64.
- Link against the target muOS EGL/GLES/SDL2/FFmpeg sysroot.
- Compile every production shader variant on the actual Mali driver.
- Test framebuffer, depth/stencil, sampler, texture upload, mip and readback paths.
- Compare deterministic output with desktop reference captures.
- Measure stalls, synchronisation, frame pacing, memory and sustained thermals.

## Canonical references

- [Full compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Graphics port design](../../../docs/h700/graphics-port.md)
- [Renderer audit](../../../docs/H700_RENDERER_AUDIT.md)
- [H700 porting plan](../../../docs/H700_PORTING_PLAN.md)
