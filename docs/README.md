![Twinsanity Rintromped H700](h700/assets/hero.svg)

# Project documentation

**Engineering reference, practical Wiki source and H700 porting handbook.**

The [GitHub Wiki](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/wiki) is the player-facing manual for installation, disc setup, mods, FAQs and troubleshooting. Its canonical tracked pages live in [wiki-source/](../wiki-source/README.md).

## 📘 H700 engineering guides

| Page | Scope |
|---|---|
| [H700 porting hub](h700/README.md) | Status, navigation and architecture |
| [Device profile](h700/device-profile.md) | Physical muOS / Mali-G31 device evidence |
| [Graphics port](h700/graphics-port.md) | SDL, EGL, GLES 3.2 and renderer adapters |
| [API compatibility matrix](h700/compatibility-matrix.md) | Desktop GL differences, GLES decisions and tests |
| [Build guide](h700/building.md) | AArch64 sysroot, CMake and CI checks |
| [muOS installation](h700/install.md) | Diagnostic utility and log locations |
| [FAQ](h700/faq.md) | Practical technical answers |
| [Roadmap](h700/roadmap.md) | Milestones and acceptance gates |

## 🧭 Original engineering plan

- [H700 porting plan](H700_PORTING_PLAN.md) — development phases and hardware acceptance.
- [H700 renderer audit](H700_RENDERER_AUDIT.md) — source-level OpenGL/GLES analysis.

## Publishing the Wiki

The tracked pages in [wiki-source/](../wiki-source/README.md) are canonical. Validate them with python tools/validate_wiki.py and publish from a local authenticated clone using sh tools/publish_wiki.sh.

> **Evidence rule:** the physical EGL/GLES and SDL presentation tests passed, but the NativeEE game renderer and gameplay remain unvalidated.
