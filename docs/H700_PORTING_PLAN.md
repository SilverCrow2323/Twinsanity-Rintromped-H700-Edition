![H700 porting](h700/assets/hero.svg)

# H700 porting plan

## 🎯 Scope

Bring Twinsanity Rintromped to Allwinner H700 handhelds running muOS without regressing Windows, macOS, Linux desktop or PS Vita targets.

This is an engineering plan, not a compatibility claim. The physical graphics preflight passed; the complete game renderer and gameplay have not yet been validated on the handheld.

## ✅ Verified baseline

On 12 November 2026, a physical device running muOS 2606.0 Andromeda (build db2a3bd0) reported:

- Allwinner sun50iw9, AArch64, four CPU cores and approximately 1 GB RAM.
- ARM Mali-G31 with Bifrost r20p0 driver.
- EGL 1.4, OpenGL ES 3.2 and GLSL ES 3.20.
- SDL2 selected the mali video driver, created a window and presented six visible colour frames.
- Display mode: 640×480p-59.

See the [device profile](h700/device-profile.md) and [API compatibility matrix](h700/compatibility-matrix.md).

## 🗺️ Work packages

~~~mermaid
flowchart TD
    A["Hardware preflight · PASS"] --> B["GLES build profile"]
    B --> C["Compile all renderer units"]
    C --> D["Shader + surface validation"]
    D --> E["First NativeEE frame"]
    E --> F["Game boot and runtime"]
    F --> G["Performance + release"]
~~~

### 1. Platform and renderer profile

- Select H700 explicitly with PS2R_GLES; never infer GLES from AArch64.
- Forward the profile and sysroot paths through the application ExternalProject to NativeEE.
- Link GLESv2 in the H700 application path while keeping desktop OpenGL unchanged.
- Keep the SDL mali driver as the verified device-facing path.

**Exit gate:** root application and NativeEE configure with the same target sysroot and graphics profile.

### 2. Renderer compile gate

- Compile the actual GL backend and SDL platform source files against GLES 3.2 headers.
- Remove or adapt desktop-only entry points without changing unrelated platform paths.
- Keep the compile-only target separate from the game executable.

**Exit gate:** all selected AArch64 renderer translation units compile with warnings treated as errors.

### 3. Shader and surface validation

- Compile every engine shader variant on the Mali-G31.
- Verify GLSL precision and the PS2 S/T/Q interpolation path.
- Test FBO completeness and color, depth and stencil attachments.
- Validate texture uploads, mip tails, buffer streaming, synchronization and readback.
- Compare deterministic captures with desktop references.

**Exit gate:** the engine's render-target and shader test scenes match expected reference output.

### 4. First NativeEE-rendered frame

- Initialise the renderer through the real application composition root.
- Draw a deterministic scene through the production backend, not a standalone SDL sample.
- Present through the normal application path.
- Save a screenshot and a log containing renderer, shader, surface and frame-time data.

**Exit gate:** the first engine-rendered frame is visible on the physical H700 panel.

### 5. Game runtime integration

Only after the renderer's first frame is stable:
- Validate the game module and user-provided ISO loading.
- Map physical controls using measured muOS input events.
- Initialise audio and check underruns.
- Verify disc streaming, memory cards, settings, safe exit and repeated cold launches.

**Exit gate:** stable boot to the title screen and representative gameplay with working controls and audio.

### 6. Performance, packaging and release

Measure frame-time distribution, CPU/GPU cost, peak memory, streaming stalls and thermals. Then create an upgrade-safe muOS package that preserves user-owned game data.

## 🧪 Hardware validation matrix

| Test | Required evidence | State |
|---|---|---|
| EGL display and GLES context | Device log | <strong>PASS</strong> |
| SDL window and buffer swaps | Six visible colour frames | <strong>PASS</strong> |
| Real renderer compile | AArch64 CI compile gate | Pending result |
| Engine shader variants | On-device compile log | Pending |
| Render targets / depth / stencil | FBO and image tests | Pending |
| First NativeEE frame | Physical screenshot + log | Pending |
| Game boot / input / audio / ISO | Hardware test session | Pending |
| Performance / thermal / shutdown | Sustained device measurements | Pending |

## Release rule

Do not call the H700 port playable, stable or release-ready on the strength of a cross-compile or diagnostic probe alone. Release notes must identify the tested device, firmware, build commit and completed hardware gates.
