# H700 porting status

**Physical graphics preflight: PASS. GLES profile and initial adapters: implemented. Full renderer and gameplay: not yet validated.**

## Current status

| Area | Status | Evidence |
|---|---|---|
| Upstream baseline | Ready | Original baseline remains on `main` |
| H700 branch | Active | `h700/porting`; work isolated from upstream baseline |
| EGL / GLES | **Device PASS** | EGL 1.4, GLES 3.2, Mali-G31 |
| SDL window / buffer swaps | **Device PASS** | SDL `mali` backend; six visible colour frames |
| muOS diagnostic package | **CI PASS** | `.muxapp` built and inspected; root is `TwinsanityRintromped/`; no ISO bundled |
| Device inventory | Collected | muOS 2606.0, sun50iw9, kernel 4.9.170 |
| Root CMake H700 profile | Added | `PS2R_GLES`; application and NativeEE both select GLES headers |
| GLES dependency path | Added | `GLES3/gl32.h`, `libGLESv2`, imported `OpenGL::GL` interface |
| SDL context selection | Added | Requests ES 3.2 and rejects lower returned versions |
| Shader conversion adapter | Added | GLSL 410 core → ES 320; source-level regression guard |
| GLES API adapters | Initial set added | Uniforms, depth clear, mip dimensions, draw buffers, map flags |
| Renderer compile gate | **CI PASS** | NativeEE renderer and SDL source objects cross-compiled with AArch64 GCC and ARM64 GLES/SDL development headers |
| Production shader smoke | **Mesa CI PASS** | Real `GlShaderLibrary::Build()` compiled/linked required programs under Mesa GLES; Mali execution still pending |
| First NativeEE frame | Pending | Requires Mali shader report, GS surface validation and real engine composition root |
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

Verified CI snapshot: commit `70a603d490a7b9977509874720551c5280bc9f43` passed `host-checks`, `gles-renderer-compile`, `gles-shader-mesa-smoke` and `aarch64-package` on 13 November 2026. The artifact contains three ELF64/AArch64 diagnostics; their maximum required GLIBC symbol is `GLIBC_2.17`. The shader smoke is linked against the Debian Bullseye ARM64 EGL/GLES sysroot and run under Mesa in CI. This does not prove compatibility with muOS's Mali EGL/GLES runtime or correct game images.

## Next gates

1. Install the CI `.muxapp` on the physical H700 and collect all four reports, especially `gles-shader-report.txt`.
2. Resolve any Mali-only shader compile/link differences; keep Mesa and Mali evidence separate.
3. Configure and link the full NativeEE application and game runner against an H700-compatible sysroot (not yet built by the diagnostic pipeline).
4. Validate GS render targets, depth/stencil attachments, texture uploads/mips, copies and readback.
5. Present the first NativeEE-rendered frame through the normal SDL application path.
6. Only then begin game boot, input/audio, disc streaming, saves and performance work.

## Canonical documentation

The player-facing Wiki and the engineering handbook are maintained separately. The canonical H700 engineering guides live in [docs/h700](../../../docs/h700/README.md):

- [Graphics port](../../../docs/h700/graphics-port.md)
- [GLES compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Build guide](../../../docs/h700/building.md)
- [Porting roadmap](../../../docs/h700/roadmap.md)
