# H700 port status

This page separates the existing TwinsanityEvolved build from the work needed for an H700 handheld port.

## What is known

- The Allwinner H700 brief identifies a quad-core Cortex-A53 CPU and a G31 GPU ([Allwinner H700 brief](https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf)).
- Arm documents Mali-G31 support for OpenGL ES 1.1 / 2.0 / 3.2 and Vulkan 1.2 ([Arm Mali-G31 product page](https://support.arm.com/compute-ip/mali-g31)).
- The current repository README lists a Linux AArch64 build, but its desktop release notes specify OpenGL 4.1.
- The engine SDL context requests OpenGL 4.1 core; its shader source uses `#version 410 core`.
- The shader path uses `noperspective` in the S/T/Q interpolation contract. The [GLSL ES 3.20 core specification](https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html) only lists `smooth` and `flat`; the equivalent output must be proven in the renderer tests.
- The PS Vita build uses a separate vitaGL/GXM path. It is not an H700 build.

## Current diagnostic milestone

The dedicated branch [h700/porting](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/tree/h700/porting) now contains two independent device probes:

- **EGL/GLES pbuffer:** tests default-display initialisation and an off-screen ES context.
- **SDL/GLES window:** requests ES 3.2, creates a 640×480 window and swaps six colour frames so the display path can be observed.

The successful [H700 CI run #43306974401](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43306974401) passed host tests, AArch64 cross-build, ELF/GLIBC checks, package verification and artifact upload. It produced the diagnostic artifact `twinsanity-rintromped-h700-preflight`.

This proves that the diagnostic binaries and muOS archive build correctly. It does **not** prove that the H700 device can initialise its graphics stack; no physical device report has been reviewed yet. The [engineering PR #2](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/pull/2) is intentionally kept in draft.

## What is not confirmed

- A successful launch on an RG35XX H or another H700 device.
- Compatibility with muOS's display and graphics stack.
- A working gamepad mapping, audio device, suspend/resume path or package installer.
- Performance, frame pacing, memory use or thermal behaviour on the handheld.

> [!IMPORTANT]
> **MUST KNOW!!** Do not label the H700 port as playable or release-ready until a real device reaches the title screen and completes the hardware test matrix in the development plan.

## Engineering gates

1. **Platform audit** — identify every host OpenGL dependency, the current context creation path, SDL use, audio backend, file I/O assumptions and runtime library requirements.
2. **Graphics decision** — evaluate an EGL + OpenGL ES 3.2 backend against the actual renderer requirements. Consider Vulkan only if the existing rendering architecture and target firmware make it the safer path.
3. **Handheld host layer** — connect display, input, audio, timing, storage and exit behaviour to the target firmware without breaking desktop or PS Vita builds.
4. **Performance pass** — measure CPU time, draw-call cost, GPU time, texture uploads, streaming stalls and peak memory on the H700.
5. **muOS package** — produce a dedicated installable package with only program files and lawful project assets. The user supplies the disc image.
6. **Device validation** — test boot, title, gameplay, audio, controls, saves, disc streaming, shutdown and recovery on the actual handheld.

For the exact source-level blockers, see [the renderer audit](../docs/H700_RENDERER_AUDIT.md) and [the full porting plan](../docs/H700_PORTING_PLAN.md).

## What to use today

- Use the desktop release on a supported PC.
- Use the PS Vita VPK only on a compatible PS Vita setup.
- Treat the H700 work as an engineering target until this page records a tested device, firmware version, build identifier and results.

---
