# Twinsanity Evolved / MuOS

Twinsanity Evolved is being brought to the **Allwinner H700 handheld environment running MuOS**. The player-facing documentation is intentionally limited to this target.

> [!IMPORTANT]
> You need your own legally obtained Crash Twinsanity disc image. Never upload it to this repository, issues, pull requests or public file shares.

## Start here

- [MuOS Field Guide](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/blob/main/site/index.html) — player-facing scope, package status, installation workflow, data safety and troubleshooting.
- [H700 / MuOS port status](H700-port-status) — current engineering gates and device validation.
- [Discs and game data](Discs-and-game-data) — user-owned media and data handling, once paths are confirmed for the MuOS package.
- [Troubleshooting](Troubleshooting) — collecting useful device reports.
- [FAQ](FAQ) — short answers for the MuOS target.

## Project status

The H700 preflight package is diagnostic. A successful AArch64 build or installable diagnostic `.muxapp` does **not** establish that the game is playable on hardware.

The H700/MuOS target remains unvalidated until graphics, display, input, audio, disc streaming, saves, sustained gameplay and clean shutdown pass on a real device. The exact tested device model and MuOS version must accompany every accepted result.

## Principles

- Keep player instructions focused on MuOS and H700.
- Keep the original disc image outside the source tree and out of releases.
- Back up saves before experimental installs or upgrades.
- Treat CI success as build evidence, never as hardware acceptance.
- Keep implementation notes in the repository's engineering documentation.

---
