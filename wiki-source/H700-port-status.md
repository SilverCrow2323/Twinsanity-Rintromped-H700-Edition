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

The physical test confirms SDL → EGL → GLES 3.2 on the documented muOS/Mali-G31 device. Separately, CI on head `e58a5fba` passed the real NativeEE GLES renderer/SDL AArch64 compile and the production shader library smoke under Mesa. The complete `twinsanityevolved` runner linked as ELF64/AArch64 with a maximum required `GLIBC_2.30`, and the full muOS package was built and inspected.

This validates the cross-compilation, shader-smoke, ELF/GLIBC and packaging gates. It does **not** prove that the production shaders behave correctly on Mali or that the game has rendered its first NativeEE frame on the handheld.

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
    A["EGL / GLES / SDL physical preflight · PASS"] --> B["NativeEE GLES renderer compile · CI PASS"]
    B --> C["Production shader smoke on Mesa · CI PASS"]
    C --> D["Full AArch64 runner + muOS muxapp · CI PASS"]
    D --> E["First NativeEE-rendered frame on Mali · pending"]
    E --> F["Game boot and title"]
    F --> G["Controls · audio · disc streaming"]
    G --> H["Performance and release"]
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

A full H700 candidate `.muxapp` is available from [H700 workflow run 43399059636](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43399059636). The package SHA-256 is `d6143bc85895e398b78185f83cfd149c4b7295aea278d24725e986e37ebe755d` (5,643,365 bytes). It has the exact `TwinsanityRintromped/` root and contains `mux_launch.sh` and `mux_lang.ini`; it excludes `game.iso` and `disc-image.txt`.

This is a CI build candidate, not a published release and not proof of a playable game. For physical testing, install the candidate and place your own ISO at `MUOS/application/TwinsanityRintromped/game.iso`. Collect `logs/gles-shader-report.txt` and `logs/game-launch.log`; the first NativeEE frame, boot, controls, audio/video and performance remain pending.