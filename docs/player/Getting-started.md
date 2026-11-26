# Getting started

Install the latest published build for a platform listed in [Supported platforms](Supported-platforms), then select your own Crash Twinsanity disc image on first launch.

## Before you start

- Have your own Crash Twinsanity `.iso` disc image ready.
- Leave enough free storage for the extracted program and your personal game folder.
- Use a release archive that matches your operating system and CPU architecture.
- Do not use a Linux AArch64 archive as proof that an H700 handheld is supported; see [H700 port status](H700-port-status).

> [!IMPORTANT]
> **MUST KNOW!!** The release contains the program, libraries, licences, tools and supported mods/language files — not the original game data.

## Desktop install

1. Open the project's Releases page and download the launcher for your desktop, or the standalone game archive for your system.
2. Extract the standalone archive to a folder you control.
3. Start `twinsanityevolved` (`twinsanityevolved.exe` on Windows).
4. On first launch, choose your own disc image when asked.
5. Keep the game folder together: it holds settings, memory cards and mods.

The launcher can find discs in common folders and removable drives. You can also drop a disc image on its window or choose it manually.

## Where data is stored

- `disc-image.txt` remembers the selected disc.
- `userdata/` stores settings and personal data beside the program folder.
- `memcards/` contains memory-card saves.
- `mods/` contains imported and enabled mods.

An earlier `~/.twinsanityevolved` data folder continues to be used when present.

## Save compatibility

- Memory-card saves are separate from save states.
- Save states belong to the build that created them; a new game build may not load an older state.
- Keep a backup of the whole game folder before testing an experimental build.

## Related pages

- [Supported platforms](Supported-platforms)
- [Discs and game data](Discs-and-game-data)
- [H700 port status](H700-port-status)
