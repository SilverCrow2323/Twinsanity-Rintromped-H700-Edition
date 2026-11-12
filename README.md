![Twinsanity Rintromped — H700 Edition](docs/h700/assets/hero.svg)

<div align="center">

# Twinsanity Rintromped · H700 Edition

**A native H700 adaptation of the TwinsanityEvolved engine — built for muOS Andromeda.**

[![H700 CI](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml/badge.svg?branch=h700%2Fporting)](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/workflows/rintromped-h700.yml)
![Platform](https://img.shields.io/badge/platform-H700%20%2F%20AArch64-173b4b)
![Graphics](https://img.shields.io/badge/graphics-OpenGL%20ES%203.2-257c67)
![Status](https://img.shields.io/badge/port-status%3A%20in%20development-d49d3a)

</div>

---

## Project status

<blockquote>
<strong>Hardware graphics preflight: PASS.</strong> The physical H700 successfully initialised EGL 1.4, created an OpenGL ES 3.2 context on the Mali-G31, and presented SDL frames through muOS's <code>mali</code> video driver.

<strong>This is not yet a playable game build.</strong> The engine's GLES renderer is being adapted and compiled independently before the first engine-rendered frame can be claimed.
</blockquote>

| Milestone | Status |
|---|---|
| H700 EGL / GLES 3.2 | <strong>Passed on device</strong> |
| SDL window and buffer presentation | <strong>Passed on device</strong> |
| Dedicated Linux GLES build profile | In progress |
| Real renderer compile gate | CI validation |
| First NativeEE-rendered frame | Pending |
| Game boot and gameplay | Pending |

## What is this?

This repository keeps the upstream TwinsanityEvolved baseline intact on the **main** branch and isolates handheld work on **h700/porting**.

The H700 path targets muOS Andromeda on Allwinner H700 devices. It uses SDL2's Mali video driver and the system EGL / GLES implementation rather than the desktop OpenGL 4.1 path.

- Upstream project: [menaman123/TwinsanityEvolved](https://github.com/menaman123/TwinsanityEvolved)
- H700 implementation and hardware notes: [docs/h700](docs/h700/README.md)
- Development roadmap: [docs/h700/roadmap.md](docs/h700/roadmap.md)

## Documentation

| Guide | What you'll find |
|---|---|
| [H700 project hub](docs/h700/README.md) | Project overview, verified status and navigation |
| [Device profile](docs/h700/device-profile.md) | Actual H700 hardware, firmware and graphics report |
| [Graphics port](docs/h700/graphics-port.md) | EGL, SDL, GLES 3.2 and renderer compatibility work |
| [API compatibility matrix](docs/h700/compatibility-matrix.md) | Desktop GL differences, GLES decisions and tests |
| [Build guide](docs/h700/building.md) | Build profile, compile checks and CI workflow |
| [muOS installation](docs/h700/install.md) | Diagnostic app installation and log locations |
| [FAQ](docs/h700/faq.md) | Practical answers and troubleshooting |
| [Roadmap](docs/h700/roadmap.md) | Staged porting plan and acceptance criteria |

## Development principles

- Keep the upstream desktop, Windows and Vita paths isolated from H700-specific code.
- Gate the H700 backend explicitly; never infer GLES solely from AArch64.
- Prefer small, measurable compatibility changes over broad source rewrites.
- Treat a successful compile as compile evidence, not as proof of correct rendering.
- Keep game images and copyrighted assets out of releases. Users provide their own legally obtained disc image.

## Important

No game ISO, proprietary firmware blob or copyrighted game assets are distributed here. The current H700 diagnostic package is a hardware test utility, not a game launcher or playable port.
