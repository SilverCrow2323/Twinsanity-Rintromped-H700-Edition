# Twinsanity Evolved — H700 / MuOS porting plan

## Scope

This project’s player target is the **Allwinner H700 handheld environment running MuOS**. This plan covers the renderer, handheld integration, MuOS packaging and real-device acceptance. It is not a compatibility claim.

The H700 brief identifies a quad-core Cortex-A53 CPU and Mali-G31 GPU. The device's actual graphics stack, MuOS runtime and available libraries must be measured on the target hardware; host builds are not a substitute.

References:
- [Allwinner H700 brief](https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf)
- [Arm Mali-G31 product support](https://support.arm.com/compute-ip/mali-g31)
- [MuOS documentation](https://muos.dev/)

See [H700 renderer audit](H700_RENDERER_AUDIT.md) for the source-level graphics findings.

## Current checkpoint

The development branch has produced diagnostic EGL/GLES pbuffer and SDL2 window/context/swap tests. The recorded CI run [#43306974401](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43306974401) passed host checks and AArch64 package verification and uploaded a diagnostic preflight `.muxapp`.

**This is not a playable game package.** The next required evidence comes from the actual H700 device running the target MuOS version: device inventory, EGL/GLES report, SDL display/input report and package installation behaviour.

## Work packages

### 1. MuOS and device inventory

- Record the exact handheld model, board revision where available and installed MuOS version.
- Inventory the firmware's kernel, libc, SDL, EGL, GLES, audio and input interfaces.
- Record display dimensions, refresh behaviour, GPU driver and available shared libraries.
- Verify storage mount points and permissions without assuming paths from another firmware.

**Exit gate:** a reproducible device inventory and dependency matrix from the real handheld.

### 2. Graphics backend

- Complete the EGL + OpenGL ES audit against every renderer dependency.
- Identify shader language/version gaps, framebuffer formats, sync requirements and extensions.
- Prototype context creation, shader compilation, texture upload, render-target use and presentation on device.
- Capture logs for both successful and failed initialisation paths.

**Exit gate:** stable frame presentation on the actual H700/MuOS combination, not only a host pbuffer test.

### 3. Handheld runtime integration

- Confirm the display lifecycle and input API exposed by the installed MuOS version.
- Map physical controls using on-device input reports; do not assume button numbering.
- Initialise audio through the supported device backend and measure underruns.
- Verify monotonic timing, file access, removable storage and clean process exit.
- Keep user-owned disc images and save data outside immutable application assets.

**Exit gate:** reach the game title screen with working display, controls and audio, then exit cleanly.

### 4. Performance and data safety

- Measure CPU and GPU frame time separately; report distributions rather than peak FPS.
- Profile draw calls, render-target switches, texture uploads and shader compilation.
- Measure disc streaming stalls, peak memory and save/load latency.
- Run sustained sessions and inspect thermal or stability regressions.
- Keep caches bounded and logs useful without unbounded growth.

**Exit gate:** repeatable gameplay sessions with documented frame pacing, memory use and data integrity.

### 5. MuOS package

- Produce a dedicated MuOS `.muxapp`; do not relabel a generic AArch64 archive as a MuOS release.
- Include only the executable, required runtime libraries, project-owned assets and licence notices.
- Document the exact user-data and disc-image paths in the package release notes.
- Define launcher behaviour, log location, uninstall behaviour and upgrade-safe save handling.
- Validate package contents and ensure no copyrighted game data is bundled.
- Verify install, launch, update and removal through the supported MuOS package workflow.

**Exit gate:** the package installs, launches, updates and uninstalls cleanly on the named device and firmware.

## Hardware acceptance matrix

Every report must include device model, MuOS version, package checksum and tested commit.

| Test | Required evidence |
|---|---|
| Install | MuOS accepts the package; install log captured |
| Cold boot | Application starts after a full device power cycle |
| Display | Correct orientation, stable image, no corruption |
| Controls | Confirmed mapping for every required action |
| Audio | Output works without repeated underruns |
| Disc I/O | Supported user-owned image loads and streams correctly |
| Gameplay | Title, hub and representative streamed areas |
| Saves | Memory-card save/load and recovery after restart |
| Performance | Frame-time distribution and sustained-session results |
| Thermals | No instability during a documented session |
| Shutdown | Clean exit; no damaged user data |
| Upgrade/removal | Existing saves survive upgrade; uninstall leaves user data as documented |

## Release rule

Do not call the H700 port playable, stable or release-ready based on compilation or package creation alone. A player release must identify the tested H700 model and MuOS version, attach the package checksum, list completed hardware gates and disclose remaining limitations.
