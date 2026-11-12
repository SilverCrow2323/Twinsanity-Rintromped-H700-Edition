![Twinsanity Rintromped H700](assets/hero.svg)

# H700 Porting Hub

**The technical home for bringing Twinsanity Rintromped to Allwinner H700 handhelds running muOS Andromeda.**

<blockquote>
<strong>Current checkpoint · Hardware graphics preflight passed.</strong>
The device creates an EGL 1.4 display, a GLES 3.2 context and a visible SDL window using the Mali video driver. The game renderer itself is still under adaptation.
</blockquote>

[![Build](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml/badge.svg?branch=h700%2Fporting)](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml)

## At a glance

| Target | Verified profile |
|---|---|
| Firmware | muOS 2606.0 Andromeda |
| SoC | Allwinner H700 · sun50iw9 |
| CPU | AArch64 · 4× Cortex-A53 class cores |
| GPU | ARM Mali-G31 · Bifrost r20p0 |
| Graphics | EGL 1.4 · OpenGL ES 3.2 · GLSL ES 3.20 |
| Display | 640×480 at approximately 59 Hz |
| Window system | SDL2 · video driver: mali |

## Documentation map

| Page | Use it for |
|---|---|
| [Device profile](device-profile.md) | Read the real device report and tested capabilities |
| [Graphics port](graphics-port.md) | Understand the SDL → EGL → GLES path and renderer adaptations |
| [API compatibility matrix](compatibility-matrix.md) | Track desktop GL differences, GLES decisions and validation state |
| [Build guide](building.md) | Configure the GLES profile and run compile checks |
| [muOS installation](install.md) | Install the diagnostic utility and retrieve reports |
| [FAQ & troubleshooting](faq.md) | Quick answers, known limits and common problems |
| [Roadmap](roadmap.md) | Milestones, entry criteria and what remains |

## Architecture

The following is the **intended H700 graphics route**. The SDL and EGL/GLES device-facing stages are confirmed; the engine renderer integration remains in development.

~~~mermaid
flowchart LR
    A["muOS Andromeda"] --> B["SDL2 · mali video driver"]
    B --> C["EGL 1.4"]
    C --> D["OpenGL ES 3.2"]
    D --> E["NativeEE GLES adapter"]
    E --> F["GS render targets"]
    F --> G["SDL buffer swap"]
~~~

## Progress board

| Workstream | State | Evidence |
|---|---|---|
| EGL display + pbuffer | <strong>PASS</strong> | Physical H700 report |
| SDL window + GLES context | <strong>PASS</strong> | Six visible colour frames |
| H700 CMake profile | Added | Root app and NativeEE both select GLES headers; CI compile gate pending |
| GLSL ES conversion | Added | Runtime adapter and source-level regression guard; Mali shader test pending |
| GLES API compatibility | Initial adapters added | Compile gate and device workload tests pending |
| Full renderer compile | CI validation | AArch64 compile-only target added |
| First engine-rendered frame | Pending | Requires successful compile and device run |
| Gameplay | Pending | Not yet available |

## Project rules

- **No platform leakage:** desktop GL, Windows and Vita behavior must remain unchanged.
- **Explicit target:** H700 is a dedicated Linux/GLES profile, not an architecture guess.
- **Evidence before claims:** compile, context creation, rendering and gameplay are separate milestones.
- **User-owned game data:** the repository and diagnostic package do not contain a game ISO.

<details>
<summary>How to report a problem</summary>

Include the exact device model, muOS build, the action you performed and the relevant log. For graphics problems attach the files from the application's logs directory. Remove personal paths or data before sharing.

</details>

---

[Repository](../../) · [H700 branch](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/tree/h700/porting) · [CI runs](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions?query=branch%3Ah700%2Fporting)
