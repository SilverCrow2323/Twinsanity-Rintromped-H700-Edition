# Discs and game data

The program contains the port and engine code. It reads the original game data from a disc image that you provide.

## 💿 Disc images

The launcher asks for a Crash Twinsanity ISO on first launch.

| Known disc | Identifier |
|---|---|
| PAL | SLES-52568 |
| North American | SLUS-20909 v2.00 |

The launcher identifies a disc by its contents, not only by its filename. Modified images may be identified as modified; support depends on the patch and its format.

> [!IMPORTANT]
> **MUST KNOW!!** Keep your disc image private and outside Git. Never attach it to issues, pull requests, CI artifacts or public support requests.

## 📁 Personal data

| Item | Purpose |
|---|---|
| disc-image.txt | Selected disc image path |
| userdata/ps2r.ini | Game settings |
| memcards/ | Memory-card saves |
| mods/ | Imported modifications |

The launcher prepares and updates the game folder. The game reads the selected disc image at runtime.

## 🧾 Safe bug reports

Share the build version, operating system or firmware, device model, relevant settings and a short log excerpt. Remove personal paths, usernames and device identifiers.

Never share the ISO or copyrighted game files.

## Related guides

[Getting started](Getting-started) · [Mods](Mods) · [H700 port status](H700-port-status)
