# Supported platforms

Use a release that explicitly matches your system. The existence of a CPU-compatible archive is not enough to prove that a device's graphics driver, display stack or input path is supported.

## Current release targets

The repository README lists builds for:

- Windows x64.
- macOS on Apple silicon (arm64).
- macOS x86_64.
- Linux x86_64.
- Linux AArch64.
- PS Vita, with its own native console build and VPK package.

The launcher is published for Windows, macOS and Linux desktop systems.

## H700 handhelds

> [!IMPORTANT]
> **MUST KNOW!!** H700 / muOS support is not established by the Linux AArch64 desktop archive. The H700 port has its own graphics, display, input, audio, runtime and packaging requirements. See [H700 port status](H700-port-status).

## Graphics requirements

The current player-facing release notes specify a graphics driver with OpenGL 4.1 for the desktop build. The H700's Mali-G31 class GPU exposes a different embedded graphics API path; the renderer must be audited and ported deliberately rather than assuming desktop OpenGL compatibility.

## How to check a release

1. Read the release's asset name and notes.
2. Match the operating system and CPU architecture.
3. Check the documented graphics requirements.
4. For handheld targets, look for a device-specific validation note — not just a successful cross-compile.

---
