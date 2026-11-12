# Twinsanity Rintromped — H700 Edition

Downstream H700 porting work for [TwinsanityEvolved](https://github.com/menaman123/TwinsanityEvolved).

> **Status: bring-up / preflight only. This is not a playable H700 port and no installable game package is published.**

## Goals

- Allwinner H700 / Cortex-A53 / ARM64 handhelds.
- Mali-G31 GPU through the EGL + OpenGL ES stack supplied by the firmware.
- muOS Andromeda first; keep the platform layer portable to other H700 firmware.
- Preserve upstream history and keep H700 work isolated from `main`.

## Branches

- `main`: upstream fork baseline; do not put H700-specific changes here.
- `h700/porting`: downstream H700 bring-up and renderer work.

## Current milestone

**M0 — device/runtime inventory**

- EGL/GLES preflight probe prepared.
- H700 system-report script prepared.
- muOS diagnostic launcher scaffold prepared.
- Host-side checks pass.
- AArch64 cross-build and physical H700 run are pending.
- SDL/EGL window presentation and the GLES renderer are not implemented yet.

## Technical constraint

Upstream desktop Linux requests OpenGL 4.1 core and uses desktop-only GL calls. The Vita lane is not a reusable GLES renderer: it has its own platform setup and the common draw backend is disabled there. Rintromped therefore needs a real GLES backend for the H700 rather than a relabelled Linux ARM64 binary.

## Source and build

The bring-up kit is versioned separately under this folder. It contains the EGL/GLES probe, muOS launcher scaffold, build/package scripts, and test protocol. It contains no game ISO, copyrighted game assets, or proprietary firmware files.

The diagnostic `.muxapp` produced by the first CI stage is only a hardware-reporting utility; it is not the game.

## Upstream pin

See `upstream.lock` for the exact upstream repository and commit used as the baseline.

## Licensing / assets

This fork retains upstream files and notices. No game disc image or game assets are included. Users must supply their own legally obtained game image for any future playable build.
