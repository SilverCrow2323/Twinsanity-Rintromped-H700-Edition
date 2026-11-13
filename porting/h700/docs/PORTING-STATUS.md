# H700 porting status

**Latest complete H700 CI: PASS on code commit `d9c9840fc60cda9afcfe895b8360bc542ee25a61`, run [#289](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948). All six jobs passed, including the full game/NativeEE AArch64 link and the full muOS `.muxapp`. The current branch HEAD is `25847674d3167c8c15cfda5af5b19e58bfdffec5`, which is a later documentation-only descendant; do not attribute the #289 run to that later SHA. Physical EGL/GLES/SDL preflight passed on 12 November 2026. Production NativeEE shaders on Mali, first NativeEE frame and gameplay remain NOT YET VALIDATED.**

## Current status

| Area | Status | Evidence |
|---|---|---|
| Upstream baseline | Ready | Original baseline remains on `main` |
| H700 branch | Active | `h700/porting`; work isolated from upstream baseline |
| EGL / GLES / SDL preflight | **Historical device PASS** | muOS 2606.0 Andromeda, Mali-G31; EGL 1.4, GLES 3.2, SDL `mali` driver and six visible colour frames on 12 November 2026 |
| Device inventory | Collected | Allwinner `sun50iw9`, kernel 4.9.170, muOS 2606.0 |
| Root CMake H700 profile | Added | `PS2R_GLES`; application and NativeEE both select GLES headers |
| GLES dependency path | Added | `GLES3/gl32.h`, `libGLESv2`, imported `OpenGL::GL` interface |
| SDL context selection | Added | Requests ES 3.2 and rejects lower returned versions |
| Shader conversion adapter | Added | GLSL 410 core → ES 320; source-level regression guard |
| GLES API adapters | Initial set added | Uniforms, depth clear, mip dimensions, draw buffers, map flags |
| Renderer compile gate | **CI PASS** | NativeEE renderer and SDL source objects cross-compiled with AArch64 GCC and ARM64 GLES/SDL development headers |
| Production shader smoke | **Mesa CI PASS** | Real `GlShaderLibrary::Build()` compiled/linked required programs under Mesa llvmpipe; this is not a Mali result |
| Full NativeEE application link | **AArch64 CI PASS** | Full `twinsanityevolved` game/NativeEE runner linked as ELF64/AArch64; maximum required GLIBC symbol `GLIBC_2.30` |
| Full muOS package | **CI PASS + ZIP inspected** | Full runner, probes, launcher, diagnostics and licences; single root `TwinsanityRintromped/`; no ISO or disc selection bundled |
| Mali production shader compile/link | Pending | Requires a new physical-device report from the H700 |
| GS surfaces / depth-stencil / texture / readback | Pending | Device render-target and image comparison tests remain |
| First NativeEE-rendered frame | Pending | Requires Mali runtime and engine composition to present a real game frame |
| Game runtime / gameplay | **Build PASS / device pending** | No physical boot, input, audio/video, disc streaming or gameplay report for this package |

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
- [Windows workflow](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/windows.yml)
- [Wiki and documentation validation](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/wiki-docs.yml)

## Verified full H700 build · run #289

Exact tested code SHA: `d9c9840fc60cda9afcfe895b8360bc542ee25a61`  
Run: [`43434846948`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948) · 13 November 2026 · all six jobs passed:

- `host-checks`
- `gles-renderer-compile`
- `gles-shader-mesa-smoke`
- `aarch64-package`
- `full-app-aarch64-link`
- `full-app-muxapp`

The full runner `twinsanityevolved` is an ELF64 little-endian AArch64 PIE executable, 15,416,144 bytes, and requires at most `GLIBC_2.30`, within the Debian Bullseye GLIBC 2.31 baseline. The full link log contains the build of `runner/te_autopilot.cpp` and no longer reports the previous `-Wmisleading-indentation` warning for that file.

The full inner `.muxapp` is 5,645,597 bytes. Its SHA-256 is:

```text
2fbabe69621b8d2a3cd75d2d04b995f1f84718ad5db2efd89a9b23aea4c87ea8
```

The sidecar `Twinsanity-Rintromped-H700-Edition.muxapp.sha256` matches the actual inner package bytes. The downloaded outer GitHub Actions ZIP was also checked against the Actions artifact digest. The inner file has a valid ZIP `PK` signature, passes CRC/integrity testing, contains 14 file entries under exactly one root `TwinsanityRintromped/`, and includes the AArch64 runner, `mux_launch.sh`, `mux_lang.ini`, three diagnostics, device collector, README/release notes, performance marker and FFmpeg/TwinsanityEvolved licence payload. It contains neither `game.iso` nor `disc-image.txt`.

### Artifacts and retention

| Artifact | ID | Outer ZIP size | Expires (UTC) |
|---|---:|---:|---|
| Full `.muxapp` | `14043202595` | 5,560,772 B | 27 Nov 2026 13:42:05 |
| Full AArch64 runner | `14043722079` | 5,636,884 B | 27 Nov 2026 13:41:33 |
| Diagnostic preflight | `14043651388` | 391,690 B | 27 Nov 2026 13:37:16 |

Full package: [download from run #289](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948/artifacts/14043202595).  
Full runner: [download from run #289](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948/artifacts/14043722079).  
Preflight: [download from run #289](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948/artifacts/14043651388).

The Mesa shader smoke used Mesa GLES 3.2 with software renderer llvmpipe. It proves production shader compile/link on that software implementation only, not the Mali driver or final image correctness.

### Remaining compiler warnings

The previous `te_autopilot.cpp` misleading-indentation warning is absent from the full AArch64 build log. Other non-blocking warnings remain: wasm-ld function-signature mismatch warnings; enum/non-enum conditional-expression warnings in NativeEE graphics sources; an unused `world` parameter and unused CPU-profiler variables. These did not block the AArch64 link or package.

## Launcher and Windows matrix

On launcher workflow run [#205](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434944588), exact workflow commit `ce5dc4c6acb1f3b3992faf75f3d525c30fa48afc`:

- Linux x86_64 AppImage: **PASS**; artifact `14042881686` downloaded and ZIP/AppImage/sidecar SHA-256 verified.
- Windows x64 launcher: **PASS**.
- macOS ARM64: queued on `macos-15`; not yet validated.

The prior `macos-14` job was cancelled before its first step because GitHub retired that Actions image. The workflow was moved to `macos-15` in commit `ce5dc4c6acb1f3b3992faf75f3d525c30fa48afc`. Do not mark macOS as passed until the new job completes.

The separate Windows application workflow [#205](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434944650) passed on the same workflow SHA.

## Next device acceptance gates

1. Install the full CI `.muxapp` on the physical H700 and record the exact artifact ID, code commit and inner package SHA-256.
2. Collect the device inventory and preflight reports; validate production shader compilation/linking on Mali-G31.
3. Validate GS render targets, depth/stencil attachments, texture uploads/mips, copies and readback on Mali.
4. Present the first NativeEE-rendered frame through the normal SDL application path.
5. Only after first frame, verify game boot, controller mapping, audio/video, disc streaming and saves.
6. Measure frame pacing, stutter, thermals and sustained gameplay.

No new user-supplied device report for this full package has been received. Therefore Mali production shaders, first NativeEE frame and gameplay remain unverified.

## Canonical documentation

The player-facing Wiki and the engineering handbook are maintained separately. The canonical H700 engineering guides live in [docs/h700](../../../docs/h700/README.md):

- [Graphics port](../../../docs/h700/graphics-port.md)
- [GLES compatibility matrix](../../../docs/h700/compatibility-matrix.md)
- [Build guide](../../../docs/h700/building.md)
- [Installation guide and device sequence](../../../docs/h700/install.md)
- [Porting roadmap](../../../docs/h700/roadmap.md)
