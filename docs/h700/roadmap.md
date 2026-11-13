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

## ✅ CI evidence — 13 November 2026

Commit `70a603d490a7b9977509874720551c5280bc9f43` passed all four H700 workflow jobs: host checks, AArch64 renderer/SDL compile, production shader smoke on Mesa and AArch64 diagnostic packaging. The generated `.muxapp` was retrieved and inspected: correct `TwinsanityRintromped/` root, three ELF64/AArch64 diagnostics, and no game ISO. This establishes a repeatable diagnostic build; it does **not** establish Mali shader success or a playable game.

| Stage | Exit criteria | State |
|---|---|---|
| 1 · Hardware preflight | EGL 1.4, GLES 3.2, SDL Mali window and visible swaps | **Passed on physical H700** |
| 2 · GLES compile + link | Renderer and SDL source objects cross-compile for AArch64; diagnostic shader executable links against ARM64 EGL/GLES | **Passed in CI** (`70a603d4`) |
| 3 · Production shaders | Required NativeEE programs compile/link in Mesa and on Mali-G31 | **Mesa CI passed**; physical Mali run pending |
| 4 · GS surfaces | FBO, depth/stencil, textures, mipmaps and readback validated | Pending |
| 5 · First engine frame | NativeEE presents a deterministic renderer-generated frame | Pending |
| 6 · Game boot | Game reaches title and first interactive scene | Pending |
| 7 · Runtime systems | Controls, audio, ISO streaming, saves and clean exit | Pending |
| 8 · Release | Stable frame pacing, thermals, install/update and docs | Pending |

## 1 — Hardware preflight · PASSED

- EGL 1.4 and GLES 3.2 initialise on the tested H700.
- SDL selects the `mali` video backend.
- A real SDL window creates an ES 3.2 context and presents six visible colour frames.
- Device profile and extension list are recorded in the engineering docs.

## 2 — GLES compile and link

- [x] Cross-compile the selected real NativeEE renderer and SDL source units for AArch64 against ARM64 GLES/SDL headers.
- [x] Build and link the NativeEE shader diagnostic executable against the ARM64 EGL/GLES sysroot.
- [x] Keep desktop, Windows and Vita paths covered by their separate build workflows.
- [ ] Link the full application and NativeEE runtime against the actual muOS sysroot.
- [x] Make the renderer compile and Mesa shader smoke gates blocking in CI.

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

## 6–8 — Game runtime and release

Only after the first NativeEE frame is correct should the project proceed to game boot, controller mapping, audio, disc streaming, save data and performance work.

The final release gate includes repeatable cold boot, stable gameplay, clean shutdown, upgrade-safe muOS packaging, user-data preservation, clear troubleshooting guides and a reproducible CI artifact.

## Definition of done

A playable H700 release must repeatedly boot the user's own game image, render representative scenes correctly, accept controls, play audio, stream disc data, save/load, exit cleanly and sustain an agreed performance/thermal target. Every claim must be backed by physical-device evidence.

[Back to the H700 hub](README.md) · [Graphics port](graphics-port.md) · [Build guide](building.md)
