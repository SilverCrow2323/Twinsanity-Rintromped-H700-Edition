# H700 porting status

**CI PASS on `h700/porting` head `e58a5fba` (run `43399059636`): full AArch64 runner and full muxapp built. Physical EGL/GLES preflight: PASS. First NativeEE frame and gameplay on Mali: NOT YET VALIDATED.**

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

Verified CI snapshot: current `h700/porting` commit `e58a5fba82bc4e1d4c382e11584f161894f9d5eb`, H700 run `43399059636` (13 November 2026), passed all six jobs: `host-checks`, `gles-renderer-compile`, `gles-shader-mesa-smoke`, `full-app-aarch64-link`, `aarch64-package` and `full-app-muxapp`. The full runner `twinsanityevolved` is ELF64/AArch64 and requires at most `GLIBC_2.30`, within Debian Bullseye GLIBC 2.31. The full `.muxapp` is 5,643,365 bytes; SHA-256 `d6143bc85895e398b78185f83cfd149c4b7295aea278d24725e986e37ebe755d`. It contains the single `TwinsanityRintromped/` root, `mux_launch.sh`, `mux_lang.ini`, the full runner, diagnostics and FFmpeg licence payload; it does not contain `game.iso` or `disc-image.txt`. GitHub uploaded `twinsanity-rintromped-h700-full-muxapp` (5,555,771 bytes; artifact ZIP digest `a8a0acc3b107941787e359b384758e96a09233ac072ed47ba4754e502f53a8ca`). The diagnostic probe ELFs require at most `GLIBC_2.17`. These are CI build/package results, not proof of compatibility with muOS's Mali EGL/GLES runtime or a playable game.

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
