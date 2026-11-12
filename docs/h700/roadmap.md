# Porting roadmap

The port moves through evidence gates. A later stage does not start merely because an earlier one compiles.

## Milestone map

~~~mermaid
flowchart TD
    A["1 · Hardware preflight"] --> B["2 · GLES compile gate"]
    B --> C["3 · Shader and surface tests"]
    C --> D["4 · First NativeEE frame"]
    D --> E["5 · Game boot sequence"]
    E --> F["6 · Input, audio and disc streaming"]
    F --> G["7 · Performance and release"]
~~~

## Current status

| Stage | Exit criteria | Status |
|---|---|---|
| 1 · Hardware preflight | EGL 1.4, GLES 3.2, SDL mali window and visible swaps | <strong>Passed on device</strong> |
| 2 · GLES compile gate | All selected renderer and SDL TUs compile for AArch64 | CI validation |
| 3a · Production shader smoke | NativeEE shader library compiles/links in a headless GLES 3.2 context | CI bring-up |\n| 3 · Shader and surface tests | Every shader variant compiles; FBO, depth, textures and readback validated | Pending |
| 4 · First engine frame | NativeEE renders a deterministic frame on the H700 panel | Pending |
| 5 · Game boot | Game's first interactive scene reaches a stable frame | Pending |
| 6 · Runtime systems | Input, audio, ISO streaming, save paths and exit flow work | Pending |
| 7 · Release | Stable performance, thermal behavior, install/update and documentation | Pending |

## Stage 2 · GLES compile gate

- Compile the full GL backend with GLES 3.2 headers.
- Resolve remaining desktop-only symbols with explicit adapters.
- Keep desktop, Windows and Vita preprocessor paths unchanged.
- Make the compile job a required dependency of diagnostic packaging CI.

## Stage 3 · Shader and surface validation

- Compile every shader variant on the Mali-G31.
- Verify GLSL precision and interpolation behavior.
- Exercise framebuffer completeness and color/depth/stencil attachments.
- Validate texture uploads, mip tails, ASTC capability checks and readback alignment.
- Compare deterministic captures to desktop reference frames.

## Stage 4 · First NativeEE frame

- Initialise the renderer from the actual engine composition root.
- Draw a test scene through the production backend, not a standalone SDL sample.
- Present through the real application path.
- Save the capture and log the GPU, API, shader results and frame timing.

## Stages 5–7 · Runtime and release

Only after the engine-rendered frame is stable should work expand to game boot, disc access, controller mapping, audio, save data and performance tuning. Final packaging must preserve the muOS archive layout and keep user-owned game data outside releases.

## Definition of done

A playable build requires repeatable boot and gameplay on physical H700 hardware, correct rendering across tested scenes, working input/audio/disc access, clean shutdown and a reproducible release package. A green compile job alone is not enough.
