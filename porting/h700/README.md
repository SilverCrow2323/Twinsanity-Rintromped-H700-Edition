# Twinsanity Rintromped - H700 Edition

**Version 0.2.3-dev. Hardware graphics preflight passed on a physical H700; not a playable port.**

Downstream H700 work for the upstream [TwinsanityEvolved](https://github.com/menaman123/TwinsanityEvolved) project. The original fork baseline is kept on `main`; H700 changes live on `h700/porting` under `porting/h700/`.

## Current milestone: physical EGL + SDL/GLES preflight PASS

The CI-built muOS diagnostic package is **`Twinsanity-Rintromped-H700-Preflight.muxapp`**. It has now been run on a physical muOS 2606.0 Andromeda H700 device. Both graphics tests passed:

- **EGL/GLES pbuffer:** EGL 1.4, ARM vendor, Mali-G31, OpenGL ES 3.2 and GLSL ES 3.20.
- **SDL/GLES window:** SDL selected the `mali` video driver, created a window and ES 3.2 context, and successfully swapped six solid-colour frames to the display.
- **Device profile:** Allwinner sun50iw9, AArch64, kernel 4.9.170, 640×480p-59 display mode, approximately 1 GB RAM.

This confirms the firmware's EGL/GLES initialisation and SDL presentation path. It does **not** run the game's shaders, renderer, level logic or gameplay.

## Install the diagnostic utility on muOS Andromeda

1. Download `Twinsanity-Rintromped-H700-Preflight.muxapp` from the latest successful H700 Actions run's artifact `twinsanity-rintromped-h700-preflight`.
2. Copy the `.muxapp` file into the `ARCHIVE` folder on SD1.
3. Open **Applications → Archive Manager** and install it.
4. Launch **Twinsanity Rintromped** from Applications.
5. Retrieve reports from `MUOS/application/TwinsanityRintromped/logs/`:
   - `muos-device-report.txt`
   - `egl-gles-report.txt`
   - `sdl-window-report.txt`

The archive root contains `TwinsanityRintromped/` directly, with `mux_launch.sh`, `mux_lang.ini`, `device/`, `logs/` and both probe executables inside it. It does not ship or replace `game.iso`; a user-provided image remains user data. The launcher follows the muOS Application Runner contract: `func.sh`, `SETUP_APP`, and the bind-mounted application path `/run/muos/storage/application/TwinsanityRintromped`.

## Renderer blocker

Upstream Linux requests desktop OpenGL 4.1 core and GLSL 4.10. The Vita path is GXM-specific and is not a drop-in GLES renderer. A separate H700 GLES backend is required.

The next milestone is a minimal engine-side GLES prototype: shader compilation, vertex/index buffers, textures and an offscreen framebuffer, followed by comparison against desktop captures. The hardware probes are not a playable port.

## Status

- Upstream fork baseline: preserved on `main`.
- H700 branch: `h700/porting`.
- EGL/GLES pbuffer probe: physical device PASS.
- SDL window / GLES 3.2 context / buffer-swap probe: physical device PASS.
- Host checks, AArch64 builds and GLIBC baseline: checked in CI.
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
