# Changelog

## 0.2.3-dev

- Corrected the installable `.muxapp` layout: `TwinsanityRintromped/` is the single top-level archive directory, without an extra `application/` wrapper.
- Tightened archive verification to reject nested roots, require launcher/language/diagnostic assets and preserve the user's separately supplied `game.iso`.
- Added the full NativeEE AArch64 application/runner link and a full-game candidate `.muxapp` alongside the diagnostic preflight package.
- H700 run `43436273369` passed all six jobs on `bd57d0a9ac52f0959a561b8bea03452d015331c2`; the runner is ELF64/AArch64 and requires at most `GLIBC_2.30`.
- The full package passed ZIP, root-layout and licence checks and excludes `game.iso` and `disc-image.txt`.
- Physical first NativeEE frame, Mali rendering, game boot, controller, audio/video, disc streaming and gameplay remain unverified.

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
