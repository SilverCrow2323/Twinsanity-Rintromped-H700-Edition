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

| Stage | Exit criteria | State |
|---|---|---|
| 1 · Hardware preflight | EGL 1.4, GLES 3.2, SDL Mali window and visible swaps | **Passed on physical H700** |
| 2 · GLES compile + link | Renderer and SDL units compile; target libraries resolve | CI validation pending |
| 3 · Production shaders | NativeEE shader library builds on Mali-G31 | Mesa smoke added; device test pending |
| 4 · GS surfaces | FBO, depth/stencil, textures, mipmaps and readback validated | Pending |
| 5 · First engine frame | NativeEE presents a deterministic renderer-generated frame | Pending |
| 6 · Game boot | Game reaches title and first interactive scene | Pending |
| 7 · Runtime systems | Controls, audio, ISO streaming, saves and clean exit | Pending |
| 8 · Release | Stable frame pacing, thermals, install/update and docs | Pending |

## 1 — Hardware preflight <badge status="success">Passed</badge>

- EGL 1.4 and GLES 3.2 initialise on the tested H700.
- SDL selects the `mali` video backend.
- A real SDL window creates an ES 3.2 context and presents six visible colour frames.
- Device profile and extension list are recorded in the engineering docs.

## 2 — GLES compile and link

- [ ] Make the dedicated `PS2R_GLES` profile compile the complete NativeEE renderer.
- [ ] Resolve every desktop-only symbol with a narrow GLES adapter or explicit fallback.
- [ ] Cross-link against the intended AArch64/muOS runtime libraries.
- [ ] Keep desktop, Windows and Vita compile paths unchanged.
- [ ] Make the compile/link gate blocking in CI.

## 3–4 — Production shaders and GS surfaces

- [ ] Execute the real `GlShaderLibrary::Build()` on the Mali-G31.
- [ ] Compile every shader branch and report the failing source/program by name.
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
