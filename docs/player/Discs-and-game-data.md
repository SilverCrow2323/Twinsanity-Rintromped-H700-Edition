# Discs and game data

The port runs its own program code and reads the original game data from a disc image that you provide.

## Disc images

- The game asks for a Crash Twinsanity `.iso` on first launch.
- The README documents the PAL disc (SLES-52568) and North American disc (SLUS-20909 v2.00).
- The launcher recognises a disc by its contents, not only by its filename.
- A modified disc may be identified as modified; support for a patch depends on the patch type and the mod workflow.

> [!IMPORTANT]
> **MUST KNOW!!** Keep your disc image private and outside Git. Do not attach it to issues, pull requests, CI artefacts or public support requests.

## Personal data

The game folder keeps the user's data together:

| Item | Purpose |
|---|---|
| `disc-image.txt` | Remembers the selected disc image |
| `userdata/ps2r.ini` | Game settings |
| `memcards/` | Memory-card saves |
| `mods/` | Imported mods |

The launcher prepares and updates the game folder, while the game itself reads the selected disc at run time.

## Safe sharing for bug reports

Share the build version, operating system or firmware, device model, settings relevant to the issue and a short log excerpt. Remove personal paths, usernames and device identifiers. Never share the disc image or copyrighted game files.

## Related pages

- [Getting started](Getting-started)
- [Mods](Mods)
- [H700 port status](H700-port-status)
