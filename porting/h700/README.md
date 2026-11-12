# Twinsanity Rintromped - H700 Edition

**Version 0.2.1-dev. Bring-up project only; not a playable port.**

Downstream H700 work for the upstream TwinsanityEvolved project. The original fork baseline is kept on main; H700 changes live on h700/porting under porting/h700/.

## Current milestone: device preflight

The diagnostic utility inspects EGL/GLES, graphics vendor/renderer/version, selected limits, runtime environment, muOS/kernel information, framebuffer and GPU device nodes. It is not the game and contains no game assets.

## Build and test

Install the AArch64 cross compiler, binutils, file, zip and unzip. From porting/h700 run scripts/test-kit.sh, scripts/build-probe.sh and scripts/package-muxapp.sh. GitHub Actions performs host checks and a Debian Bullseye AArch64 cross-build, then publishes a diagnostic .muxapp artifact.

## Install on muOS Andromeda

Place the workflow artifact Twinsanity-Rintromped-H700-Preflight.muxapp in ARCHIVE on SD1 and install it with Applications → Archive Manager. Launch Twinsanity Rintromped in Applications. Retrieve egl-gles-report.txt and muos-device-report.txt from MUOS/application/TwinsanityRintromped/logs/.

The launcher follows the muOS Application Runner contract and uses the bind-mounted runtime path /run/muos/storage/application/TwinsanityRintromped.

## Renderer blocker

Upstream Linux requests desktop OpenGL 4.1 core and GLSL 4.10. The Vita path is GXM-specific and is not a drop-in GLES renderer. A separate H700 GLES backend is required. A successful preflight does not establish renderer compatibility.

## Status

- Upstream fork baseline: preserved on main.
- H700 branch: h700/porting.
- Probe and muOS diagnostic launcher: source added.
- Host-side checks: passing locally.
- AArch64 CI build: configured, pending workflow execution.
- Physical H700 run: pending.
- SDL presentation and GLES renderer: not implemented.
- Playable game build: not available.

No game ISO, proprietary firmware blob or copyrighted game assets are included.

## References

- Upstream: https://github.com/menaman123/TwinsanityEvolved
- muOS Application Runner: https://community.muos.dev/t/application-runner/1282
- muOS installable archives: https://community.muos.dev/t/manually-creating-installable-archives/824
- muOS 2606.0 Andromeda: https://muos.dev/release/current/2606_0
