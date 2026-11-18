# H700 / MuOS port status

This page records the work required to run Twinsanity Evolved on an Allwinner H700 handheld with MuOS. It distinguishes build evidence from actual device acceptance.

## What is known

- The Allwinner H700 brief identifies a quad-core Cortex-A53 CPU and a G31 GPU ([Allwinner H700 brief](https://www.allwinnertech.com/uploads/pdf/2021070513595227.pdf)).
- Arm documents Mali-G31 support for OpenGL ES 1.1 / 2.0 / 3.2 and Vulkan 1.2 ([Arm Mali-G31 product page](https://support.arm.com/compute-ip/mali-g31)).
- The engine's existing renderer baseline targets desktop OpenGL 4.1; H700/MuOS requires a separate EGL/OpenGL ES adaptation. This compatibility boundary remains **unvalidated on hardware**; an AArch64 build does not establish it.
- The [GLSL ES 3.20 specification](https://registry.khronos.org/OpenGL/specs/es/3.2/GLSL_ES_Specification_3.20.html) and the renderer's shader requirements must be reconciled and tested on the target GPU.

## Diagnostic milestone

The development branch contains two diagnostic probes:

- **EGL/GLES pbuffer:** tests default-display initialisation and an off-screen ES context.
- **SDL/GLES window:** requests ES 3.2, creates a 640×480 window and swaps six colour frames so the display path can be observed.

The recorded [H700 CI run #43306974401](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43306974401) passed host checks, AArch64 cross-build, ELF/GLIBC checks, package verification and artifact upload. It produced the diagnostic artifact `twinsanity-rintromped-h700-preflight`.

This proves that the diagnostic binaries and MuOS archive build correctly. It does **not** prove that a physical H700 device can initialise its graphics stack or run the game. No hardware acceptance is claimed.

## Not yet confirmed

- Successful launch on a named H700 handheld and MuOS version.
- Working display, renderer and shader pipeline.
- Physical gamepad mapping and audio output.
- Suspend/resume and package install/update/removal behaviour.
- Disc streaming, save/load, performance, memory use or thermal stability.

> [!IMPORTANT]
> Do not label the H700 port playable or release-ready until a real device reaches the title screen and completes the hardware acceptance matrix.

## Engineering gates

1. **Device inventory** — record model, MuOS version, kernel/runtime, display, GPU driver and available libraries.
2. **Graphics** — validate EGL/GLES context creation, shaders, textures, render targets and frame presentation.
3. **Runtime** — validate input, audio, timing, storage, process lifecycle and clean exit.
4. **Performance** — measure frame-time distribution, GPU/CPU cost, streaming stalls and peak memory.
5. **MuOS package** — produce a dedicated `.muxapp`, document exact user-data paths and verify install/update/removal.
6. **Hardware validation** — test boot, title, representative gameplay, audio, controls, saves, disc streaming, shutdown and recovery.

See [the renderer audit](../docs/H700_RENDERER_AUDIT.md) and [the full porting plan](../docs/H700_PORTING_PLAN.md).

## Release rule

Every accepted player release must identify the tested handheld model, MuOS version, build commit and package checksum, and list completed tests and known limitations.
