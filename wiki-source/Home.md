# Twinsanity Rintromped

![H700 graphics hardware preflight](https://raw.githubusercontent.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/h700/porting/docs/h700/assets/hero.svg)

**A native Crash Twinsanity project built around the NativeEE engine.** This Wiki is the practical guide for installing the program, preparing your own disc image, managing mods and solving common problems.

> [!IMPORTANT]
> **MUST KNOW!!** The program does not include the original game data. You must provide your own legally obtained Crash Twinsanity disc image. Never upload the ISO or copyrighted game files to GitHub, issues, pull requests or public file shares.

## 🚀 Start here

| Guide | What it helps you do |
|---|---|
| [Getting started](Getting-started) | Download, install and launch a supported build |
| [Supported platforms](Supported-platforms) | Check the actual release targets and requirements |
| [Discs and game data](Discs-and-game-data) | Choose your own ISO and understand user-data folders |
| [Mods](Mods) | Import, enable and order supported modifications |
| [Troubleshooting](Troubleshooting) | Diagnose common launch, graphics and mod problems |
| [FAQ](FAQ) | Find quick answers |

## 🎮 Project status

Desktop and PS Vita builds are separate release targets. The H700 handheld work now has a **physical graphics preflight PASS**: muOS Andromeda successfully initialised EGL 1.4, GLES 3.2 and SDL window presentation on a Mali-G31.

<blockquote>
<strong>Important distinction:</strong> the H700 graphics preflight does not mean the game is playable on the handheld. The NativeEE renderer, game boot, controls, audio and disc streaming still need validation.
</blockquote>

Read [H700 port status](H700-port-status) for the current evidence and limitations.

## 🧭 Project principles

- Keep the original disc image outside the source tree and public repositories.
- Keep settings, memory cards and mods in the user's game folder.
- Treat CI success as build evidence, not as proof of gameplay compatibility.
- Use this Wiki for practical player instructions; use the repository's docs/ for engineering detail.

---

[Project repository](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition) · [Releases](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/releases)
