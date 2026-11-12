# Twinsanity Rintromped - H700 Edition

**Version 0.2.1-dev. Device preflight package available; not a playable port.**

Downstream H700 work for the upstream [TwinsanityEvolved](https://github.com/menaman123/TwinsanityEvolved) project. The original fork baseline is kept on `main`; H700 changes live on `h700/porting` under `porting/h700/`.

## Current milestone: first ARM64 diagnostic package

The first CI-built muOS diagnostic package is available as **`Twinsanity-Rintromped-H700-Preflight.muxapp`**. It is a hardware-inventory utility, not the game. It checks EGL/GLES context creation and records the graphics vendor, renderer, version, selected limits, runtime environment, muOS/kernel information, framebuffer and GPU device nodes.

- AArch64 ELF cross-build: passed.
- Maximum required GLIBC symbol: `GLIBC_2.17`.
- muOS archive structure and ZIP integrity: passed.
- GitHub Actions: [successful build run](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43301695175).
- The report has **not** yet been collected from a physical H700 device.

## Install the diagnostic utility on muOS Andromeda

1. Download `Twinsanity-Rintromped-H700-Preflight.muxapp` from the successful Actions run's artifact `twinsanity-rintromped-h700-preflight`.
2. Copy the `.muxapp` file into the `ARCHIVE` folder on SD1.
3. Open **Applications → Archive Manager** and install it.
4. Launch **Twinsanity Rintromped** from Applications.
5. Retrieve both reports from `MUOS/application/TwinsanityRintromped/logs/`:
   - `muos-device-report.txt`
   - `egl-gles-report.txt`

The launcher follows the muOS Application Runner contract: `func.sh`, `SETUP_APP`, and the bind-mounted application path `/run/muos/storage/application/TwinsanityRintromped`.

## Renderer blocker

Upstream Linux requests desktop OpenGL 4.1 core and GLSL 4.10. The Vita path is GXM-specific and is not a drop-in GLES renderer. A separate H700 GLES backend is required. The current probe creates a small EGL pbuffer; it does **not** test SDL window presentation or game rendering. A successful report does not establish renderer compatibility.

## Status

- Upstream fork baseline: preserved on `main`.
- H700 branch: `h700/porting`.
- Probe and muOS diagnostic launcher: committed.
- Host checks: passing.
- AArch64 ELF build: passing.
- GLIBC baseline: `2.17`.
- Diagnostic `.muxapp`: built and uploaded by CI.
- Physical H700 run: pending.
- SDL window / EGL presentation: not implemented.
- GLES renderer: not implemented.
- Playable H700 game build: not available.

No game ISO, proprietary firmware blob or copyrighted game assets are included.

## Developer tools

From `porting/h700/`:

- `scripts/test-kit.sh` — host-side syntax, compile and package-safety checks.
- `scripts/build-probe.sh` — AArch64 probe build.
- `scripts/package-muxapp.sh` — diagnostic archive creation and layout verification.
- `scripts/prepare-upstream.sh` — checkout the pinned upstream source.
- `scripts/inspect-upstream-release.sh` — inspect the upstream Linux ARM64 release ABI and GLIBC needs.
- `tools/gl_api_inventory.py` — inventory GL function calls, constants and shader version directives for manual GLES classification.

## References

- Upstream: https://github.com/menaman123/TwinsanityEvolved
- muOS Application Runner: https://community.muos.dev/t/application-runner/1282
- muOS installable archives: https://community.muos.dev/t/manually-creating-installable-archives/824
- muOS 2606.0 Andromeda: https://muos.dev/release/current/2606_0
