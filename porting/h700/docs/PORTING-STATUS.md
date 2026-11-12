# H700 porting status

**Physical graphics preflight: PASS. GLES profile and initial adapters: implemented. Full renderer and gameplay: not yet validated.**

## Current status

| Area | Status | Evidence |
|---|---|---|
| Upstream baseline | Ready | Original baseline remains on `main` |
| H700 branch | Active | `h700/porting`; work isolated from upstream baseline |
| EGL / GLES | **Device PASS** | EGL 1.4, GLES 3.2, Mali-G31 |
| SDL window / buffer swaps | **Device PASS** | SDL `mali` backend; six visible colour frames |
| muOS diagnostic package | Packaged | AArch64 probes; archive root is `TwinsanityRintromped/` |
| Device inventory | Collected | muOS 2606.0, sun50iw9, kernel 4.9.170 |
| Root CMake H700 profile | Added | `PS2R_GLES`; application and NativeEE both select GLES headers |
| GLES dependency path | Added | `GLES3/gl32.h`, `libGLESv2`, imported `OpenGL::GL` interface |
| SDL context selection | Added | Requests ES 3.2 and rejects lower returned versions |
| Shader conversion adapter | Added | GLSL 410 core → ES 320; source-level regression guard |
| GLES API adapters | Initial set added | Uniforms, depth clear, mip dimensions, draw buffers, map flags |
| Renderer compile gate | CI queued | AArch64 object compile against GLES and SDL headers |
| Production shader smoke | Added | Real `GlShaderLibrary` EGL/GLES test; Mesa job is non-blocking during bring-up |
| First NativeEE frame | Pending | Requires compile, Mali shader and surface validation |
| Game runtime | Not available | No playable build yet |

## Physical device profile

- muOS 2606.0 Andromeda, build `db2a3bd0`.
- Allwinner `sun50iw9`, AArch64, four cores; approximately 1 GB RAM.
- ARM Mali-G31, Bifrost `r20p0`.
- EGL 1.4 / OpenGL ES 3.2 / GLSL ES 3.20.
- SDL2 video driver: `mali`.
- Framebuffer mode: 640×480p-59.
- GPU frequency was reported as 816 MHz during collection; this is not a fixed-clock guarantee.

## CI lanes

- [H700 build workflow](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml)
- [Wiki and documentation validation](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/wiki-docs.yml)

The renderer compile job is a compile-only gate. A green result proves that the selected translation units compile against GLES headers; it does not prove target linking, shader execution, image correctness or gameplay.

## Next gates

1. Complete the AArch64 GLES compile gate and fix every real source/API failure.
2. Configure and link NativeEE plus the application against the muOS target sysroot.
3. Run every production shader variant on the actual Mali driver.
4. Validate GS render targets, depth/stencil attachments, texture paths and readback.
5. Present the first NativeEE-rendered frame.
6. Only then begin game boot, input/audio, disc streaming and performance work.

## Canonical documentation

The player-facing Wiki and the engineering handbook are maintained separately. The canonical H700 engineering guides live in [docs/h700](../../../docs/h700/README.md):

- [Graphics port](../../../docs/h700/graphics-port.md)
- [GLES compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Build guide](../../../docs/h700/building.md)
- [Porting roadmap](../../../docs/h700/roadmap.md)
