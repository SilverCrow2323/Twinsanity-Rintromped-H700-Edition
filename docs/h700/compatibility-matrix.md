# Graphics API compatibility matrix

This page is the working contract between the upstream desktop renderer and the H700 GLES 3.2 backend. A compile-time adapter is not marked visually validated until it has been exercised on the device.

## Source and context

| Component | Upstream renderer | H700 target |
|---|---|---|
| Context | OpenGL 4.1 core | OpenGL ES 3.2 |
| SDL context verification | No explicit version gate | Require returned context >= ES 3.2; log renderer and version | Added |
| Shader language | GLSL 4.10 core | GLSL ES 3.20 |
| Header | GL/glcorearb.h | GLES3/gl32.h |
| Window | SDL2 desktop GL | SDL2 mali video driver |
| GPU | General desktop GL drivers | ARM Mali-G31 · Bifrost r20p0 |

## Desktop-only assumptions

| API / feature | GLES 3.2 status | H700 decision | Validation |
|---|---|---|---|
| glProgramUniform* | Not GLES 3.2 core | Bind target program, use glUniform*, restore previous program | Compile gate; uniform correctness test pending |
| glClearDepth | Desktop spelling | Use glClearDepthf | Compile gate; depth image test pending |
| glGetTexLevelParameteriv | Not GLES 3.2 core | Derive mip width/height from base surface dimensions and mip level | Compile gate; mip-chain capture pending |
| glDrawBuffer | Desktop entry point | Use glDrawBuffers with GL_NONE for the depth/stencil-only FBO | Compile gate; FBO completeness test pending |
| GL_MAP_UNSYNCHRONIZED_BIT | Not a GLES 3.2 map flag | Omit it; preserve WRITE + FLUSH_EXPLICIT | Compile gate; streaming stress test pending |
| GL_TIME_ELAPSED desktop query path | Not directly portable | Disabled in the first GLES profile | Deferred; implement through EXT_disjoint_timer_query |
| GLSL 410 core | Desktop shader profile | Rewrite to #version 320 es and insert highp defaults | Source adapter added; device shader compilation pending |
| noperspective | Not a GLES 3.2 core interpolation qualifier | Remove only from v_texcoord; the engine path sets gl_Position.w = 1.0 | Source rationale recorded; visual comparison pending |
| glClipControl | Not used by the Linux H700 path | Keep platform-specific desktop/Windows branch out of H700 build | Compile gate |
| Program binary APIs | Not in the current H700 path | Vita shader cache remains behind PS2R_HOST_VITA | Compile gate |

## GLES core paths to exercise

These features are part of the target profile or the engine's normal GLES path. They still need runtime validation with NativeEE surfaces and workloads.

| Feature | Engine use | Device evidence / next test |
|---|---|---|
| Vertex array objects | VAO-backed mesh and quad draws | Advertised GL_OES_vertex_array_object; exercise engine VAO creation |
| Framebuffer objects | GS render targets, depth/stencil and presentation | Core GLES path; test all attachment combinations |
| Sampler objects | Per-unit filtering and wrap modes | Core GLES path; test texture-state isolation |
| Buffer mapping | Stream vertex data and explicit flush | Core GLES 3.x; test write visibility and stalls |
| Sync objects | Retire pooled textures after GPU use | Core GLES 3.x; test wait / timeout / teardown |
| Texture storage | Allocation and mip chains | Device advertises GL_EXT_texture_storage; engine path must confirm format behavior |
| Readback | Surface copies, captures and host diagnostics | Test color, depth, stencil and row alignment separately |
| ASTC | Potential compressed texture path | Driver advertises ASTC families; do not enable without format and asset-path audit |

## Known performance trade-offs

<details>
<summary>Uniform updates: correctness before throughput</summary>

The initial GLES adapter may issue a program bind and restore around each cached uniform write. It is intentionally conservative. The renderer should later batch uniform flushes while the destination program is bound, with tests that detect any mismatch between the uniform cache and GL state cache.

</details>

<details>
<summary>Mapped buffers: no unsynchronized promise</summary>

The H700 mapping flags omit the desktop-only unsynchronized hint. This can introduce synchronization or stalls that the desktop path avoided. Do not re-add a non-core flag just to chase performance; benchmark the actual buffer lifetime and use a GLES-supported ring strategy.

</details>

<details>
<summary>Timer queries: advertised extension is not an implementation</summary>

The device reports GL_EXT_disjoint_timer_query. The initial profile disables the desktop GL_TIME_ELAPSED census until the extension's exact entry points and disjoint handling are implemented. CPU timings and frame pacing remain available through the existing host-side measurements.

</details>

## Production shader smoke

A new CI harness creates a headless EGL/GLES 3.2 pbuffer and calls the real NativeEE `GlShaderLibrary::Build()` function. It checks the production PS2, scanout, dither and stencil program objects. The Mesa job is non-blocking during bring-up and validates shader compile/link behavior on Mesa; it does not validate Mali-G31 behavior or final image correctness.

## Evidence labels

- **Compile gate:** the C++ translation unit compiles against the GLES 3.2 headers.
- **Device API test:** the relevant GL operation succeeds on the actual H700 driver.
- **Image test:** output is compared with a deterministic desktop reference.
- **Gameplay test:** the path is exercised by the real game.

No item should move to a stronger evidence label without the corresponding test.
