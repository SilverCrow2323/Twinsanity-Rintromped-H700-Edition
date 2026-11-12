# H700 port status

This page separates **verified graphics hardware support** from the unfinished work required to run the actual game.

## ✅ What the physical device has passed

On 12 November 2026, the diagnostic package was run on a physical muOS Andromeda H700 handheld. Both the EGL and SDL/GLES reports were successful.

| Layer | Observed result |
|---|---|
| Firmware | muOS 2606.0 Andromeda · build db2a3bd0 |
| Kernel | Linux 4.9.170 |
| SoC family | Allwinner sun50iw9 · AArch64 |
| GPU | ARM Mali-G31 · Bifrost r20p0 |
| EGL | 1.4 · ARM vendor |
| Graphics API | OpenGL ES 3.2 |
| Shader language | GLSL ES 3.20 |
| SDL video driver | mali |
| Window presentation | Six solid-colour frames swapped visibly |
| Display mode | 640×480p-59 |

<blockquote>
<strong>Graphics preflight: PASS.</strong> The device can initialise EGL/GLES 3.2 and present an SDL window through muOS's Mali video driver.

<strong>Game port: still unvalidated.</strong> The real NativeEE renderer, game shaders, game boot and gameplay have not yet passed on the device.
</blockquote>

## 🔍 What this result means

The hardware and firmware are no longer the first unknown. We now have a confirmed SDL → EGL → GLES 3.2 path for the tested device.

The original Linux renderer still requests **OpenGL 4.1** and uses GLSL 4.10 core constructs. These are not interchangeable with GLES 3.2. A dedicated H700 renderer profile and source adapters are being developed.

The implementation currently includes an explicit GLES profile, context selection, shader-source conversion and initial API compatibility adapters. They still need a successful compile, device shader validation and output comparison.

## ⏳ What is not validated yet

- A NativeEE-rendered frame from the game's actual renderer.
- All engine shader variants and their visual equivalence.
- Game boot, title screen and interactive gameplay.
- Controller mapping, audio, disc streaming and save/load.
- Performance, sustained frame pacing, memory use and thermals.
- Upgrade-safe final muOS packaging.

> [!IMPORTANT]
> **MUST KNOW!!** Do not call the H700 port playable or release-ready until a physical device reaches gameplay and completes the hardware test matrix.

## 🧭 Engineering milestones

~~~mermaid
flowchart TD
    A["EGL / GLES / SDL preflight"] -->|PASS| B["NativeEE GLES compile"]
    B --> C["Shader + render-target tests"]
    C --> D["First engine-rendered frame"]
    D --> E["Game boot and title"]
    E --> F["Controls · audio · disc streaming"]
    F --> G["Performance and release"]
~~~

## Where to follow progress

- [H700 engineering hub](../docs/h700/README.md)
- [Graphics port and current adapters](../docs/h700/graphics-port.md)
- [API compatibility matrix](../docs/h700/compatibility-matrix.md)
- [Build guide](../docs/h700/building.md)
- [Roadmap](../docs/h700/roadmap.md)
- [the renderer audit](../docs/H700_RENDERER_AUDIT.md)
- [full porting plan](../docs/H700_PORTING_PLAN.md)
- [development branch](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/tree/h700/porting)

## What to use today

Use a published desktop build on a supported PC, or the PS Vita package on compatible Vita hardware. The H700 preflight archive is a diagnostic tool, not a game launcher. Your own game ISO remains separate user data and is not read by the current diagnostic package.
