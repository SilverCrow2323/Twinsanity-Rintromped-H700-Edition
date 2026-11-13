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
| Renderer compile gate | CI PASS (recorded combined run) | Actual GL renderer and SDL platform objects cross-compiled for AArch64 against GLES/target SDL2 headers; link/runtime still pending |
| Production shader smoke | **Blocking CI PASS (recorded combined run)** | Real `GlShaderLibrary` EGL/GLES test completed on Mesa llvmpipe; physical Mali shader execution still pending |
| AArch64 diagnostic package | CI pending (recorded combined run) | Debian 11 cross sysroot is pinned to archived Bullseye base/update packages plus the 2026-08-31 final security snapshot to preserve GLIBC 2.31; ELF/package result not yet confirmed |
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

The renderer compile job is a compile-only gate. A green result proves that the selected translation units compile against GLES/SDL2 headers; it does not prove target linking, shader execution, image correctness or gameplay. The production Mesa shader-smoke job is a required blocking CI gate. A green Mesa run is not a physical Mali-G31 test.

The AArch64 package job uses a pinned Debian 11 build sysroot because the target compatibility gate caps GLIBC at 2.31. Bullseye LTS ended on 31 August 2026, so CI resolves its base/update packages from Debian Archive and the final security index from a fixed 2026-08-31 snapshot. This snapshot is only a CI build input and does not claim that Bullseye remains supported or security-maintained.

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
