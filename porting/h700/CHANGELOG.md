# Changelog

## 0.2.5-dev

- Added an H700-only low-memory texture path: texture records keep reserved IDs but decode and create at first draw by default (`TE_GFX_EAGER_TEXTURES=2`); explicit environment overrides remain available.
- Reduced H700 GLES retained texture-cache budgets: decoded L2 64 MiB (8 MiB probation), owned unbound surfaces 32 MiB, and recycled GL texture storage 16 MiB. These are cache budgets, not a total process/GPU memory cap.
- Added H700 `/proc` telemetry for process RSS split into anonymous, file-backed and shared memory, plus system `MemAvailable`.
- Confirmed from the physical kernel report that the prior runner was killed by the OOM killer. The root source of the large file-backed RSS remains under investigation; this patch is a mitigation candidate, not a validated fix.
- Documented the PAL edition as the repeatable test baseline (50 Hz video standard; not a promise of 50 rendered FPS on H700).
- Latest full H700 build on code head f7e22324cabf38bcf370cff2632154897fbf03a9 passed all six jobs in run #44722519260; full runner is ELF64/AArch64 with GLIBC_2.30 maximum.
- Full muOS muxapp inner SHA-256: 157b1cb574574cd68009fd2aa018bcad165ab561b5550522717e563ac1a8cf7f; Actions artifact #14623421505 outer digest 935ceea794fdd51bac53197ea2236d9dd1df31cd2bbf158546857238725630a3.
- The package has one TwinsanityRintromped/ root, includes launcher/language/runtime/licence assets and excludes the user's game.iso and disc-image.txt.
- Windows and Wiki validation passed; the launcher matrix remains incomplete because macOS ARM64 was cancelled. Mali production shaders, NativeEE first frame, title boot and gameplay remain unverified.

## 0.2.4-dev

- Built and linked the full H700 AArch64 NativeEE runner on branch head `681f0b3249cbb4e3f900ff55db4db252c949e3e3`; ELF64/AArch64, maximum required GLIBC `2.30`.
- Produced and verified the full muOS `.muxapp` with a single `TwinsanityRintromped/` root; inner SHA-256 `f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53`.
- Kept the user's ISO external to the package. CI had no title ELF/disc input, so title recompilation and game composition remain unvalidated; this is not a playable-game claim.


## 0.2.3-dev

- Corrected the installable `.muxapp` layout: `TwinsanityRintromped/` is now the top-level archive directory, without an extra `application/` wrapper.
- Tightened archive verification to reject the old nested layout and require launcher, language file, device helper and both diagnostic binaries at their direct paths.
- The package remains diagnostics-only and does not contain, modify or replace a user-provided `game.iso`.

## 0.2.2-dev

- Added a dynamically loaded SDL2 window probe that requests GLES 3.2 and swaps six visible colour frames.
- The muOS launcher now runs the EGL pbuffer probe and SDL window probe independently and stores separate reports.
- Cross-builds, validates and packages both AArch64 diagnostic binaries.
- Expands the muOS test protocol to collect the SDL video driver and window/presentation result.
- Updates the H700 GitHub Actions workflow to verify both AArch64 ELFs, check the GLIBC baseline for each and upload both binaries with the diagnostic archive.
- Updates workflow actions to current Node.js 24-compatible releases.
- No game renderer or playable H700 build is included; physical device validation remains pending.

## 0.2.1-dev

- Added an EGL/OpenGL ES preflight executable for H700 firmware runtimes.
- Added a muOS Andromeda Application Runner launcher and device inventory script.
- Added AArch64 cross-build, GLIBC inspection, diagnostic muxapp packaging and host-side safety tests.
- Added an upstream GL API inventory and ABI/release inspection helpers.
- Added a CI workflow that successfully builds and uploads the first AArch64 diagnostic archive.
- Verified the diagnostic ELF as AArch64 with GLIBC_2.17 maximum and verified the nested muOS archive layout.
- Renderer porting, physical-device validation and gameplay remain pending.
