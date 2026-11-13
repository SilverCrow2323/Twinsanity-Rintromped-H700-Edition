# H700 porting status

**CI PASS on `h700/porting` code commit `0ccac64106abd9c3dcd3b657ae8a405c23ecbe2e` (H700 run `43406895561`): all six jobs passed, including the complete AArch64 NativeEE runner and full muOS `.muxapp`. The production NativeEE shader programs compiled and linked on Mesa llvmpipe. Physical EGL/GLES preflight: PASS (12 November 2026). First NativeEE-rendered frame and gameplay on Mali: NOT YET VALIDATED.**

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
| Production shader smoke | **Mesa CI PASS** | Real `GlShaderLibrary::Build()` compiled/linked required programs under Mesa llvmpipe; Mali execution remains a separate pending gate |
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
- [Launcher workflow](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/launcher.yml)
- [Wiki and documentation validation](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/wiki-docs.yml)

### Verified full H700 build

Exact tested code commit: `0ccac64106abd9c3dcd3b657ae8a405c23ecbe2e`  
H700 run: [`43406895561`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43406895561) · 13 November 2026 · all six jobs passed:

- `host-checks`
- `gles-renderer-compile`
- `gles-shader-mesa-smoke`
- `aarch64-package`
- `full-app-aarch64-link`
- `full-app-muxapp`

The full runner `twinsanityevolved` is ELF64/AArch64, 15,416,144 bytes, and requires at most `GLIBC_2.30`, within the Debian Bullseye GLIBC 2.31 baseline. The full `.muxapp` is 5,645,597 bytes; its SHA-256 is `70b53757bbb193f621fd3b081a59fa13461588849628c6e631903c333caef822`. The adjacent `.sha256` sidecar matches the downloaded archive byte-for-byte.

The inner `.muxapp` is a valid ZIP archive with 18 entries and the single root `TwinsanityRintromped/`. It contains `twinsanityevolved`, `mux_launch.sh`, `mux_lang.ini`, diagnostic probes, `logs/performance-diagnostics.once`, the device inventory collector, release notes and FFmpeg/TwinsanityEvolved licence files. It contains neither `game.iso` nor `disc-image.txt`. The runner header identifies ELF64 little-endian AArch64.

GitHub uploaded artifact `twinsanity-rintromped-h700-full-muxapp` (artifact ID `14028321169`, outer artifact size 5,560,771 bytes; expires 27 November 2026 at 10:16:45 UTC). The full runner artifact is `14028446148` and the preflight package is `14027229093`; both also have a 14-day retention.

The production shader smoke ran on Mesa GLES 3.2 with software renderer llvmpipe and reported that all required NativeEE production shader programs compiled and linked. This is not a Mali result. Likewise, AArch64 compile/link and ZIP verification do not establish hardware runtime compatibility or gameplay.

### Launcher matrix

On code commit `0ccac64106abd9c3dcd3b657ae8a405c23ecbe2e`, launcher run [`43406902769`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43406902769) built Linux x86_64 AppImage and Windows x64 successfully. The macOS ARM64 job was cancelled before producing step logs; a job-only retry was requested on 13 November 2026. macOS remains unverified until that retry reports success.

## Next gates

1. Install the full CI `.muxapp` on the physical H700 and collect `logs/gles-shader-report.txt`, `logs/game-launch.log` and the device inventory.
2. Validate production shader compilation/linking on Mali-G31 and GS render targets, depth/stencil attachments, texture uploads/mips, copies and readback.
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
