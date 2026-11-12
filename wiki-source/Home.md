# TwinsanityEvolved

A native Crash Twinsanity port built from the `twinsanity-reversed` decompilation and the NativeEE engine. The game reads your own disc image at run time; this repository and its releases do not include the original game data.

The practical Wiki is the place for installation, disc setup, mods, troubleshooting and the H700 port status.

> [!IMPORTANT]
> **MUST KNOW!!** You need your own legally obtained Crash Twinsanity disc image. Do not upload it to this repository, issues, pull requests or public file shares.

## Start here

- [Getting started](Getting-started) — download, install and launch the game.
- [Supported platforms](Supported-platforms) — what the current release targets, and what it does not promise.
- [H700 port status](H700-port-status) — the handheld target, known differences and the next engineering gates.
- [Discs and game data](Discs-and-game-data) — disc recognition and where personal data lives.
- [Mods](Mods) — supported mod formats and their limits.
- [Troubleshooting](Troubleshooting) — practical checks for common problems.
- [FAQ](FAQ) — short answers.

## Project status

The current README and release notes describe the desktop builds and the PS Vita build. A Linux AArch64 archive is listed, but that alone does **not** establish compatibility with an Allwinner H700 handheld or muOS.

The H700 work is tracked separately and remains **unvalidated on hardware** until the dedicated graphics, input, audio and packaging gates pass on the target device.

## Principles

- Keep the original disc image outside the source tree.
- Keep the game, settings, memory cards and mods in the user's game folder.
- Treat build/CI success as build evidence, not as proof of handheld compatibility.
- Keep player instructions here; keep implementation detail in the repository's `docs/`.

---
