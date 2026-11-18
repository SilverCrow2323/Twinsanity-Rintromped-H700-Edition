# H700 porting status

**Latest complete H700 CI: PASS on exact code HEAD `95732802bd5c651e83a90dfdf85d95249b3654aa`, run [#44067269456](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44067269456), with all six jobs green. The full runner is ELF64/AArch64 and requires at most `GLIBC_2.30`; the full muOS `.muxapp` passed ZIP integrity, single-root layout, diagnostics and licence-payload validation (inner SHA-256 `a088feba52ec205c558bb1918f66de041510b23981f5865abdaeb89ae51c08a3`). Full-muxapp artifact ID `14321467319`, outer ZIP 5,565,674 bytes, digest `sha256:d59fe6940c0448086a945f665c7c7470d1ab5086cc955f2652205df7471d02f9`; full-runner artifact ID `14321691939`, digest `sha256:7d3a89630d053dc9030fa1253c13ba186ea6835927545d18ce1fc06a7cbdb29e`. The build had no title ELF/disc input: game-specific recompilation and composition tests were skipped. Windows run #44067269389 and Wiki run #44067269169 passed; launcher Linux and Windows passed while macOS ARM64 remained queued at the latest check. The only physical evidence remains the 12 November EGL/GLES/SDL colour-frame preflight. Mali production shader execution, first NativeEE frame, game boot and gameplay remain NOT YET VALIDATED.**

## Current status

| Area | Status | Evidence |
|---|---|---|
| Upstream baseline | Ready | Original baseline remains on `main` |
| H700 branch | Active | `h700/porting`; work isolated from upstream baseline |
| EGL / GLES / SDL preflight | **Historical device PASS** | muOS 2606.0 Andromeda, Mali-G31; EGL 1.4, GLES 3.2, SDL `mali` driver and six visible colour frames on 12 November 2026 |
| Device inventory | Collected | Allwinner `sun50iw9`, kernel 4.9.170, muOS 2606.0 |
| Andromeda controller mapping | Host regression tests added | Active muOS mapping, selected database, system database and Retro/Modern fallback; physical controls still pending |
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

## Verified full H700 build · run #310

Exact tested branch HEAD: `681f0b3249cbb4e3f900ff55db4db252c949e3e3`  
Run: [`43844953315`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315) · 16 November 2026 · all six jobs passed:

- `host-checks`
- `gles-renderer-compile`
- `gles-shader-mesa-smoke`
- `full-app-aarch64-link`
- `aarch64-package`
- `full-app-muxapp`

The full runner `twinsanityevolved` was linked as an ELF64 little-endian AArch64 PIE executable. The link log reports a maximum required GLIBC symbol of `GLIBC_2.30`, within the pinned Debian Bullseye GLIBC 2.31 baseline.

The full muOS package is `Twinsanity-Rintromped-H700-Edition.muxapp`. Its inner package SHA-256 is:

```text
f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53
```

The uploaded full-muxapp Actions artifact is ID `14214608053`, outer ZIP size 5,561,027 bytes, Actions digest `sha256:3a53eed01fd3e43583bb13b3758aafd48b5800ce1fecc61c32b01353d5b5d8e9`. The full-runner artifact is ID `14215381134`, outer ZIP size 5,636,884 bytes, digest `sha256:7232c57f5c89a663369009346481e6a8e8dcbeeada0531e9286d704e07aa5ac2`. The diagnostic preflight artifact is ID `14214697793`, outer ZIP size 391,952 bytes, digest `sha256:b7c5a33de0cf45861658e86387b790b15e41e0e653dee4e9dbe213bad7b0f07b`.

The full package job verified ZIP integrity, the single root `TwinsanityRintromped/`, launcher/language files, runtime and licence payload. It does not contain `game.iso` or `disc-image.txt`; the launcher still expects the user's own ISO at `MUOS/application/TwinsanityRintromped/game.iso`.

**Important build boundary:** the CI runner had no title ELF or disc image. The log explicitly skipped `ps2r_title_recomp`, the game composition, title-dependent EE/CDVD tests and generated-body self-oracles. A successful generic NativeEE runner link and full package are not a first game frame and do not prove that Twinsanity boots.

The Mesa shader smoke compiled and linked the production shader library under Mesa llvmpipe. It is a blocking CI gate, but it is not a Mali result and does not prove correct render-target/readback output.

## Launcher and Windows matrix

On the exact H700 branch head `681f0b3249cbb4e3f900ff55db4db252c949e3e3`:

- Windows game build run [#221](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953505): **PASS**.
- Wiki validation run [#264](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953306): **PASS**.
- Launcher run [#221](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953522): Linux x86_64 AppImage **PASS**, Windows x64 **PASS**, macOS ARM64 **CANCELLED**. The overall launcher workflow therefore reports failure/cancellation; do not describe the three-platform matrix as green.

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


## Latest full H700 build · 17 November 2026

Exact tested code HEAD: `95732802bd5c651e83a90dfdf85d95249b3654aa`  
Run: [#44067269456](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44067269456) · all six jobs passed: host checks, GLES renderer compile, blocking Mesa shader smoke, full AArch64 link, diagnostic package and full muxapp.

- Full runner: ELF64/AArch64 PIE; maximum required GLIBC symbol `GLIBC_2.30`.
- Full muxapp inner SHA-256: `a088feba52ec205c558bb1918f66de041510b23981f5865abdaeb89ae51c08a3`.
- Full muxapp artifact ID `14321467319`; outer Actions ZIP size 5,565,674 bytes; digest `sha256:d59fe6940c0448086a945f665c7c7470d1ab5086cc955f2652205df7471d02f9`.
- Full runner artifact ID `14321691939`; outer Actions ZIP size 5,644,398 bytes; digest `sha256:7d3a89630d053dc9030fa1253c13ba186ea6835927545d18ce1fc06a7cbdb29e`.
- The package job reported ZIP integrity, single-root layout, diagnostics and licence payload verified. The package builder excludes the user's `game.iso` and `disc-image.txt`.

The runner was built without a title ELF or disc image. This remains a full NativeEE link/package milestone, not a first game frame or gameplay validation.


## Exact-head CI refresh · 18 November 2026

Current H700 PR head: `4b99499d6374b5b68c00948724d230b8aa39066e`.

The latest validation runs now complete on this documentation head:

- H700 run [#44123849723](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44123849723): **6/6 jobs passed** — host checks, GLES renderer compile, blocking Mesa shader smoke, AArch64 package, full AArch64 application link and full muxapp package.
- Windows run [#44123851074](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44123851074): **PASS**.
- Wiki validation [#44123850914](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44123850914): **PASS**.
- Launcher matrix [#44123850075](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44123850075): Linux x86_64 AppImage **PASS**, Windows x64 **PASS**, macOS ARM64 **CANCELLED**. The matrix is not fully green; the cancelled macOS lane remains a separate CI follow-up.

This confirms the current CI compile/link/package gates, not a playable-game result. The CI runner still does not contain the user's game ISO or a title ELF, and no new physical Mali report is attached to this run. Production shader execution on Mali, render-target/readback validation, first NativeEE game frame, game boot, input/audio/video gameplay and sustained performance remain unverified. Keep PR #2 in Draft and do not publish a release.
