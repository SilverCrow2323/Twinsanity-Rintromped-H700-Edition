# Twinsanity Rintromped - H700 Edition

**Version 0.2.3-dev. Device preflight package available; not a playable port.**

Downstream H700 work for the upstream [TwinsanityEvolved](https://github.com/menaman123/TwinsanityEvolved) project. The original fork baseline is kept on `main`; H700 changes live on `h700/porting` under `porting/h700/`.

## Current milestone: EGL and SDL graphics preflight

The CI-built muOS diagnostic package is **`Twinsanity-Rintromped-H700-Preflight.muxapp`**. It is a hardware-inventory utility, not the game. It contains two independent graphics probes:

- **EGL/GLES pbuffer:** loads the system EGL/GLES libraries, requests an ES 3.2 context and records the GPU, API version, selected limits and extension list.
- **SDL/GLES window:** dynamically loads the system SDL2 library, requests an ES 3.2 context, creates a 640×480 window and swaps six solid-colour frames. The panel should visibly change colour while this test runs.

The package also records the muOS/kernel environment, framebuffer and GPU device nodes, display variables and visible SDL/EGL/GLES libraries.

- AArch64 ELF cross-build: required for both probe binaries.
- GLIBC compatibility is checked during the build.
- The `.muxapp` archive starts at its root with `TwinsanityRintromped/` (no enclosing `application/` directory); its layout and ZIP integrity are checked before upload.
- GitHub Actions build history: [H700 porting runs](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions?query=branch%3Ah700%2Fporting).
- The report from a physical H700 device is still required.

## Install the diagnostic utility on muOS Andromeda

1. Download `Twinsanity-Rintromped-H700-Preflight.muxapp` from the latest successful H700 Actions run's artifact `twinsanity-rintromped-h700-preflight`.
2. Copy the `.muxapp` file into the `ARCHIVE` folder on SD1.
3. Open **Applications → Archive Manager** and install it.
4. Launch **Twinsanity Rintromped** from Applications.
5. The screen should briefly show a sequence of solid colours during the SDL window test. If no colours appear, the report records the SDL error.
6. Retrieve all reports from `MUOS/application/TwinsanityRintromped/logs/`:
   - `muos-device-report.txt`
   - `egl-gles-report.txt`
   - `sdl-window-report.txt`

The archive root contains `TwinsanityRintromped/` directly, with `mux_launch.sh`, `mux_lang.ini`, `device/`, `logs/` and both probe executables inside it. It does not ship or replace `game.iso`; a user-provided image remains user data. The launcher follows the muOS Application Runner contract: `func.sh`, `SETUP_APP`, and the bind-mounted application path `/run/muos/storage/application/TwinsanityRintromped`.

## Renderer blocker

Upstream Linux requests desktop OpenGL 4.1 core and GLSL 4.10. The Vita path is GXM-specific and is not a drop-in GLES renderer. A separate H700 GLES backend is required.

The EGL pbuffer probe checks context creation without presenting to the screen. The SDL probe now checks window creation, an ES context and buffer swaps, but it does **not** run the game's shaders, renderer or level logic. A passing diagnostic report is not a playable port.

## Status

- Upstream fork baseline: preserved on `main`.
- H700 branch: `h700/porting`.
- EGL/GLES pbuffer probe and muOS diagnostic launcher: committed.
- SDL window / GLES 3.2 context / buffer-swap probe: included in this development package.
- Host syntax, compile and package-safety checks: required in CI.
- AArch64 ELF builds and GLIBC baseline: checked in CI.
- Physical H700 report: pending.
- Full GLES game renderer: not implemented.
- Playable H700 game build: not available.

No game ISO, proprietary firmware blob or copyrighted game assets are included.

## Developer tools

From `porting/h700/`:

- `device/egl_gles_probe.c` — EGL display, pbuffer, GLES version and GPU capability inventory.
- `device/sdl_gles_probe.c` — SDL window creation, GLES context and colour-buffer swap test.
- `device/collect-system-info.sh` — muOS, kernel, framebuffer, GPU, input, audio and runtime library inventory.
- `scripts/test-kit.sh` — host-side syntax, compile and package-safety checks.
- `scripts/build-probe.sh` — AArch64 builds for both diagnostic binaries.
- `scripts/package-muxapp.sh` — diagnostic archive creation and layout verification.
- `scripts/prepare-upstream.sh` — checkout the pinned upstream source.
- `scripts/inspect-upstream-release.sh` — inspect the upstream Linux ARM64 release ABI and GLIBC needs.
- `tools/gl_api_inventory.py` — inventory GL function calls, constants and shader version directives for manual GLES classification.

## References

- Upstream: https://github.com/menaman123/TwinsanityEvolved
- muOS Application Runner: https://community.muos.dev/t/application-runner/1282
- muOS installable archives: https://community.muos.dev/t/manually-creating-installable-archives/824
- muOS 2606.0 Andromeda: https://muos.dev/release/current/2606_0
