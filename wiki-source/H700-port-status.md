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

The 12 November physical test confirms SDL → EGL → GLES 3.2 on muOS 2606.0 Andromeda / sun50iw9 / Mali-G31. A separate 13 November bring-up report records an earlier runner launch with the user's PAL `SLES-52568` image: NativeEE loaded the retail ELF, initialised gamepad/audio and created an ES 3.2 context, then failed at the first vertex shader because of a leading newline before `#version`. The shader normaliser was fixed afterwards, but no post-fix Mali retest is documented; the 13 November report lacks an exact firmware build and package hash.

CI run [#310](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315) on code head `681f0b3249cbb4e3f900ff55db4db252c949e3e3` passed all six jobs. The runner is ELF64/AArch64 with maximum required `GLIBC_2.30`; the full runner-candidate package SHA-256 is `f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53`.

**Build boundary:** CI had no title ELF/disc input. Title-specific recompilation, game composition and title-dependent EE/CDVD tests were skipped. The Mesa shader smoke is not a Mali result and does not prove a NativeEE frame.

The original desktop renderer targets **OpenGL 4.1**. The H700 GLES 3.2 path is a dedicated port and adapter layer; the successful cross-compile and Mesa smoke do not establish full OpenGL 4.1 feature equivalence or validate the production renderer on Mali. That compatibility boundary remains open until the first NativeEE frame and the device render-target/shader matrix pass.

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

The latest runner-candidate `.muxapp` is available from [H700 workflow run #310](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315), artifact ID `14214608053`. Inner package SHA-256: `f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53`. It has the exact `TwinsanityRintromped/` root and contains `mux_launch.sh` and `mux_lang.ini`; it excludes `game.iso` and `disc-image.txt`.

This is a CI runner candidate, not a published release and not proof of a playable game. CI had no title ELF/disc input, so title-specific recompilation and game composition were skipped. For physical testing, install the candidate and place your own ISO at `MUOS/application/TwinsanityRintromped/game.iso`. Collect `logs/gles-shader-report.txt` and `logs/game-launch.log`; the post-fix Mali shader run, first NativeEE frame, game boot, controls, audio/video and performance remain pending.