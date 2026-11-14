# muOS controller mapping

**H700 input follows the map selected by muOS, not a hard-coded Xbox guess.**

## Version detection

The H700 runner checks the release metadata at `/opt/muos/config/system/version` and `/etc/os-release`. The Andromeda-specific path is enabled only when the release codename is `Andromeda`; a future muOS release is not automatically assumed to retain the same input contract.

## Mapping source priority

1. The active `SDL_GAMECONTROLLERCONFIG` row exported by `SETUP_APP`.
2. The row for the connected controller GUID in `SDL_GAMECONTROLLERCONFIG_FILE`.
3. The same GUID row in muOS's active `/usr/lib/gamecontrollerdb.txt` database.
4. A minimal H700 `muOS-Keys` fallback generated from the active Retro/Modern scheme.

This preserves the selected per-device mapping and the global or content-specific scheme. The game does not force Retro or Modern.

## Standard H700 muOS-Keys contract

The H700 `muOS-Keys` device is a virtual controller. Its GUID includes the muOS virtual vendor/version identity; the product segment distinguishes the board profile. The active database row is matched by the full GUID, so RG35XX H, RG35XX SP and other supported H700 devices can retain their own profiles.

The currently documented H700 SDL rows use these button assignments:

| Control | Retro | Modern |
|---|---:|---:|
| A | b2 | b3 |
| B | b3 | b2 |
| X | b4 | b5 |
| Y | b5 | b4 |
| L1 / R1 | b6 / b7 | b6 / b7 |
| L2 / R2 | b8 / b9 | b8 / b9 |
| SELECT / back | b10 | b10 |
| START | b11 | b11 |
| MENU / Guide | b12 | b12 |
| D-pad | hat 0 | hat 0 |
| Left stick | axes 0/1 | axes 0/1 |
| Right stick, where present | axes 2/3; clicks b13/b14 | axes 2/3; clicks b13/b14 |

The full GUID-specific row from muOS wins over this summary. Some H700 boards do not expose the right stick, so absent controls remain absent.

## Exit and system shortcuts

The engine's MENU + START exit chord is now bound through the official `guide:b12` and `start:b11` controls. muOS's own system hotkey daemon remains responsible for its safe restart, shutdown and force-quit combinations; the game does not replace or intercept that daemon.

## Diagnostics

Each launch records the detected muOS version/build, board name, selected controller scheme, SDL database path and active SDL mapping in `logs/game-launch.log`. The device report also records the system version and active muOS-Keys rows. This makes it possible to distinguish a wrong profile from a controller that SDL failed to open.

For a new report, recreate `logs/performance-diagnostics.once` only when profiling is required; ordinary launches do not run the performance sampler.
