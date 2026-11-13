![H700 porting roadmap](assets/hero.svg)

# Porting roadmap

**A staged route from proven hardware access to a stable, reproducible handheld release.**

> [!IMPORTANT]
> Each milestone has an evidence gate. A green compile job does not imply that shaders, images or gameplay work on the device.

## 🧭 Milestone map

~~~mermaid
flowchart TD
    A["1 · Hardware preflight"] --> B["2 · GLES compile + link"]
    B --> C["3 · Production shader tests"]
    C --> D["4 · GS surfaces + image validation"]
    D --> E["5 · First NativeEE frame"]
    E --> F["6 · Game boot + title"]
    F --> G["7 · Input · audio · disc · saves"]
    G --> H["8 · Performance · packaging · release"]
~~~

## 📍 Current progress

## 🧪 Physical full-runner bring-up — 13 November 2026

The full runner was installed and launched on the H700 using the user's existing disc image. The launcher passed `--iso` correctly; NativeEE identified the PAL `SLES-52568` image, loaded the retail ELF, initialised the muOS gamepad and SDL audio, and created an ES 3.2 context on the Mali-G31. The first PS2 vertex shader then failed because the raw GLSL source contained a leading newline before `#version`. This is now fixed in the GLES source normaliser and the production shader library passes the Mesa GLES smoke. A separate first-run `userdata/` creation bug was fixed and covered by host regression tests.

**Milestone boundary:** actual game-runner startup and disc/ELF initialisation are now demonstrated on hardware; the first NativeEE-rendered frame, title screen and gameplay have **not** yet been demonstrated. The rebuilt full-game `.muxapp` must pass a fresh physical Mali shader run before the next milestone is marked complete.

## ✅ CI evidence — 13 November 2026

Commit `9e2b6b82ad0ea2c43fa9d5203c000074a14259de` passed all six H700 workflow jobs: host checks, production shader smoke on Mesa, AArch64 renderer/SDL compile, diagnostic package, full game/NativeEE AArch64 link and full-game muOS `.muxapp` packaging. The full runner is ELF64/AArch64, requires GLIBC up to 2.30, and has no dynamic FFmpeg dependency: FFmpeg 6.1.2's minimal MPEG-1/2 decoder + parser + swscale subset is statically linked with the LGPL v2.1+ recipe. The generated full `.muxapp` was downloaded and inspected: valid ZIP, correct `TwinsanityRintromped/` root, executable runner and three diagnostics, licence files present, no ISO or disc-selection file. This is a **CI-built release candidate**, not proof of a successful boot or playable gameplay on Mali-G31; physical-device validation remains the next gate.

| Stage | Exit criteria | State |
|---|---|---|
| 1 · Hardware preflight | EGL 1.4, GLES 3.2, SDL Mali window and visible swaps | **Passed on physical H700** |
| 2 · GLES compile + link | Renderer and SDL source objects cross-compile for AArch64; full runner links against ARM64 GLES and static LGPL FFmpeg | **Passed in CI** (`9e2b6b82`) |
| 3 · Production shaders | Required NativeEE programs compile/link in Mesa and on Mali-G31 | **Mesa CI passed** (`9e2b6b82`); physical Mali run pending |
| 4 · GS surfaces | FBO, depth/stencil, textures, mipmaps and readback validated | Pending |
| 5 · First engine frame | NativeEE presents a deterministic renderer-generated frame | Pending |
| 6 · Game boot | Game reaches title and first interactive scene | Pending |
| 7 · Runtime systems | Controls, audio, ISO streaming, saves and clean exit | Pending |
| 8 · Release | Stable frame pacing, thermals, install/update and docs | **CI candidate packaged**; physical validation pending |

## 1 — Hardware preflight · PASSED

- EGL 1.4 and GLES 3.2 initialise on the tested H700.
- SDL selects the `mali` video backend.
- A real SDL window creates an ES 3.2 context and presents six visible colour frames.
- Device profile and extension list are recorded in the engineering docs.

## 2 — GLES compile and link

- [x] Cross-compile the selected real NativeEE renderer and SDL source units for AArch64 against ARM64 GLES/SDL headers.
- [x] Build and link the NativeEE shader diagnostic executable against the ARM64 EGL/GLES sysroot.
- [x] Keep desktop, Windows and Vita paths covered by their separate build workflows.
- [x] Link the complete game + NativeEE runner for AArch64 against the Bullseye-compatible sysroot; CI checks GLIBC 2.31 baseline (runner requires up to GLIBC 2.30).
- [x] Build pinned FFmpeg 6.1.2 for AArch64 with the minimal static LGPL MPEG-1/2 + parser + swscale recipe.
- [x] Verify no dynamic FFmpeg libraries remain in the runner and retain the FFmpeg licence/build proof in the app archive.
- [x] Package the full runner and the three hardware diagnostics into a ZIP-based muOS `.muxapp`; verify root layout, executable modes, archive integrity and absence of user disc data.
- [x] Make renderer compile, Mesa shader smoke, full AArch64 link and full package gates blocking in CI.
- [ ] Run the packaged production shader smoke on the physical Mali-G31 and inspect its report.
- [ ] Boot the full-game candidate from the user's own ISO and validate title screen, controls, audio, streaming, saves and clean exit.

## 3–4 — Production shaders and GS surfaces

- [x] Execute the real `GlShaderLibrary::Build()` under Mesa GLES 3.2 in blocking CI.
- [x] Package the same NativeEE shader smoke as an AArch64 executable in the muOS diagnostic `.muxapp`.
- [ ] Execute the packaged `GlShaderLibrary::Build()` on the Mali-G31 and inspect `logs/gles-shader-report.txt`.
- [ ] Confirm every required shader program on the device and resolve any Mali-specific compiler differences.
- [ ] Test color, depth and stencil FBO combinations.
- [ ] Test texture uploads, mip tails, filtering and supported formats.
- [ ] Test copies, readback alignment and synchronization.
- [ ] Capture deterministic images and compare them against desktop references.

## 5 — First NativeEE frame

- [ ] Initialise the renderer through the actual engine composition root.
- [ ] Draw a small deterministic scene using production buffers, shaders and render targets.
- [ ] Present through the normal SDL application path.
- [ ] Record GPU/API, shader results, frame time and memory footprint.
- [ ] Validate the captured image before moving to game boot.

## 6–8 — Game runtime and release candidate

The full-game `.muxapp` now exists as a reproducible CI artifact. The next test is on the physical H700: run the diagnostic preflight first, then install the full-game candidate and record whether the runner reaches the first NativeEE frame, the game's title screen and an interactive scene.

The final stable-release gate still includes repeatable cold boot, correct rendering, controller mapping, audio, disc streaming, save/load, clean shutdown, stable frame pacing/thermals, upgrade-safe muOS packaging, user-data preservation, clear troubleshooting guides and a reproducible CI artifact.

## Definition of done

A playable H700 release must repeatedly boot the user's own game image, render representative scenes correctly, accept controls, play audio, stream disc data, save/load, exit cleanly and sustain an agreed performance/thermal target. Every claim must be backed by physical-device evidence.

[Back to the H700 hub](README.md) · [Graphics port](graphics-port.md) · [Build guide](building.md)
