# H700 porting plan

## Scope

Bring TwinsanityEvolved to an Allwinner H700 handheld and its installed firmware without regressing the existing Windows, macOS, Linux desktop or PS Vita targets.

This document is an engineering plan, not a compatibility claim. There is no H700 hardware validation recorded yet.

## Baseline

The current player README and release notes describe desktop targets, a Linux AArch64 archive and a separate PS Vita package. The desktop release notes specify OpenGL 4.1. The PS Vita path is a distinct native target.

The Allwinner H700 brief identifies a quad-core Cortex-A53 CPU and G31 GPU. Arm's Mali-G31 product material lists OpenGL ES 3.2 and Vulkan 1.2 support. Desktop OpenGL 4.1 and OpenGL ES 3.2 must not be treated as interchangeable: the actual renderer entry points, shader language, context creation and required features have to be audited.

References:
- [Allwinner H700 brief](https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf)
- [Arm Mali-G31 product support](https://support.arm.com/compute-ip/mali-g31)

See [H700_RENDERER_AUDIT.md](H700_RENDERER_AUDIT.md) for the source-level OpenGL 4.1 / SDL context / GLSL audit and the first GLES compatibility findings.\n\n## Current preflight checkpoint

The H700 development branch now produces two diagnostic executables: an EGL/GLES pbuffer test and an SDL2 window/context/swap test. GitHub Actions run [#43306974401](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43306974401) passed both host checks and AArch64 package verification and uploaded the preflight `.muxapp`.

The next evidence must come from the actual H700 device: collect the muOS inventory, EGL/GLES report and SDL window report. Do not begin claiming a renderer port from this diagnostic package alone.

## Work packages

### 1. Platform and renderer inventory

- Identify the current non-Vita host renderer and the exact OpenGL version/features it uses.
- Inventory shader versions, framebuffer/render-target behaviour, sync primitives, texture formats and optional extensions.
- Identify SDL, EGL, window-system, audio and controller dependencies.
- Record the Linux AArch64 build's actual libc and shared-library requirements.
- Separate CPU architecture support from firmware/display/GPU support.

**Exit gate:** a written dependency matrix and a reproducible cross-build baseline.

### 2. Graphics backend decision

- Evaluate an EGL + OpenGL ES 3.2 implementation against every renderer dependency.
- Identify features that need shader translation or a renderer refactor.
- Consider Vulkan only after comparing implementation cost, driver availability and memory use on the target firmware.
- Preserve the desktop backend behind an explicit build option.

**Exit gate:** a minimal renderer prototype clears a frame, uploads a texture, compiles the required shaders and presents reliably on the handheld.

### 3. Handheld host integration

- Determine the correct display/context creation path for the actual muOS version.
- Map the handheld gamepad through the firmware's actual input API; avoid assumed physical button numbering.
- Initialise audio through the supported device backend.
- Verify monotonic timing, frame pacing, file paths, removable storage and safe shutdown.
- Keep personal disc images and memory cards outside the package.

**Exit gate:** boot to the game's title screen with audio, working controls and a clean exit on the target device.

### 4. Performance and memory

- Measure CPU time, GPU time and frame pacing separately.
- Profile draw-call submission, render-target switches, texture uploads and shader compilation.
- Measure peak memory, disc-streaming stalls and save/load latency.
- Use device measurements before enabling costly visual effects or high internal resolutions.
- Add bounded caches and logs; avoid unbounded growth over long sessions.

**Exit gate:** repeatable gameplay sessions with documented frame-time and memory measurements.

### 5. muOS packaging

- Add a dedicated target package; do not relabel a desktop AArch64 archive as a handheld release.
- Include only the executable, required runtime libraries, project-owned assets and licence notices.
- Keep the disc image user-supplied and read it from a documented path.
- Provide a launcher, log location, uninstall behaviour and upgrade-safe user-data handling.
- Validate package contents with the project's asset scan and archive inspection.

**Exit gate:** package installs, launches, updates and uninstalls cleanly on the exact tested firmware.

### 6. Hardware validation matrix

Record the device model, firmware version, package checksum and build commit for every run.

| Test | Required evidence |
|---|---|
| Cold boot | Launcher and game reach title without crash |
| Display | Stable picture, correct orientation and no corruption |
| Controls | Confirmed mapping for all required actions |
| Audio | Output works without repeated underruns |
| Disc I/O | PAL and supported North American image tests, using user-owned media |
| Gameplay | Hub and representative streamed levels |
| Saves | Memory-card save/load and recovery after restart |
| Performance | Frame-time distribution, not only peak FPS |
| Thermals | No instability during a sustained session |
| Shutdown | Clean exit and no damaged user data |

## Release rule

Do not call the H700 port playable, stable or release-ready on the strength of a successful compile alone. The release note must identify the tested device and firmware and list the completed hardware gates.
