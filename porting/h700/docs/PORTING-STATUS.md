# H700 porting status

**CI: full AArch64 runner and full muxapp build PASS (13 Nov 2026). Physical graphics preflight: PASS. First NativeEE frame and gameplay on Mali: NOT YET VALIDATED.**

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
| Full NativeEE application link | **AArch64 CI PASS** | `twinsanityevolved` linked as ELF64/AArch64; maximum required GLIBC symbol `GLIBC_2.30` |
| Full muOS package | **CI PASS** | Full runner, probes and static FFmpeg licence payload packaged; exact root `TwinsanityRintromped/`, no ISO or disc selection bundled |
| First NativeEE frame | Pending | Requires Mali shader report, GS surface validation and real engine composition root |
| Game runtime | **Build PASS / device pending** | Full AArch64 runner exists; no physical game boot, first frame, input, audio or video result yet |

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

Verified CI snapshot: current `h700/porting` commit `4726e851ad0367f0ef7644097a860558e2fd0e53`, H700 run `43374362800` (13 November 2026), passed `host-checks`, `gles-renderer-compile`, `gles-shader-mesa-smoke`, `full-app-aarch64-link`, `aarch64-package` and `full-app-muxapp`. The full runner `twinsanityevolved` is ELF64/AArch64 and requires at most `GLIBC_2.30`, within the Debian Bullseye GLIBC 2.31 baseline. The full `.muxapp` SHA-256 is `5abb1a27f06f1e2a0a5b9d96251fb0ad542e5148130b42e9cf99215162f7ad6c`; the workflow verified archive integrity, the single `TwinsanityRintromped/` root, diagnostics and licence payload. It does not contain `game.iso` or `disc-image.txt`. The diagnostic probe ELFs in the same run require at most `GLIBC_2.17`. These are CI build/package results, not proof of compatibility with muOS's Mali EGL/GLES runtime or a playable game.

## Next gates

1. Install the full CI `.muxapp` on the physical H700 and collect `logs/gles-shader-report.txt`, `logs/game-launch.log` and the device inventory.
2. Validate Mali shader compilation/linking and GS render targets, depth/stencil attachments, texture uploads/mips, copies and readback.
3. Present the first NativeEE-rendered frame through the normal SDL application path; this remains the next blocking milestone.
4. Verify detection of the user's own `game.iso` in `MUOS/application/TwinsanityRintromped/`; the package intentionally contains no disc image.
5. Only after first frame, verify boot, controller mapping, audio/video, disc streaming and saves.
6. Measure frame pacing, stutter, thermals and sustained performance on the physical H700.

## Canonical documentation

The player-facing Wiki and the engineering handbook are maintained separately. The canonical H700 engineering guides live in [docs/h700](../../../docs/h700/README.md):

- [Graphics port](../../../docs/h700/graphics-port.md)
- [GLES compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Build guide](../../../docs/h700/building.md)
- [Porting roadmap](../../../docs/h700/roadmap.md)
