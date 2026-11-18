# Supported target: MuOS on H700

The only player target documented by this project is an **Allwinner H700 handheld running MuOS**.

A CPU-compatible executable or a successful cross-build is not enough to establish support. The graphics driver, display stack, input, audio, runtime libraries and package lifecycle must all work on the actual device.

## Current status

- H700 / MuOS is an active engineering target.
- The diagnostic preflight `.muxapp` checks parts of the graphics and display path.
- The diagnostic package is **not a playable game build**.
- No hardware compatibility claim is made until a named device and MuOS version pass the acceptance matrix.

## How to check a release

1. Open the project's Releases page.
2. Select an artifact explicitly labelled for MuOS / H700.
3. Read its prerequisites, exact package instructions, checksum and known limitations.
4. Confirm that the release notes name the tested handheld model and MuOS version.
5. If there is no playable MuOS artifact, do not install a diagnostic package expecting the game.

## Graphics and runtime

The H700's Mali-G31 graphics path must be validated through the target MuOS firmware. EGL/OpenGL ES context creation, shaders, frame presentation, input, audio and storage behaviour are all separate acceptance gates. See [H700 port status](H700-port-status).
