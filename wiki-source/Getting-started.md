# Getting started

This guide covers the supported desktop and console release packages. For the experimental H700 target, read [H700 port status](H700-port-status) before installing anything.

## ✅ Before you start

- Have your own Crash Twinsanity ISO ready.
- Download a release that matches your operating system and CPU architecture.
- Keep enough free space for the program and your personal game folder.
- Read the release notes, especially the graphics-driver requirements.

> [!IMPORTANT]
> **MUST KNOW!!** A Linux AArch64 archive is not automatically an H700 handheld build. The desktop release uses a different graphics path.

## 🖥️ Desktop installation

1. Open the project's [Releases](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/releases) page.
2. Download the launcher for your desktop, or the standalone archive for your system.
3. Extract the standalone archive to a folder you control.
4. Start **twinsanityevolved** (**twinsanityevolved.exe** on Windows).
5. On first launch, choose your own disc image when prompted.
6. Keep the game folder together: it stores settings, memory cards and mods.

The launcher can search common folders and removable drives. You can also drop an ISO onto its window or select it manually.

## 📁 Where your data lives

| File or folder | Purpose |
|---|---|
| disc-image.txt | Remembers the selected disc image |
| userdata/ | Settings and personal data |
| memcards/ | Memory-card saves |
| mods/ | Imported and enabled mods |

An existing ~/.twinsanityevolved data folder continues to be used when present.

## 💾 Save compatibility

- Memory-card saves and save states are different things.
- Save states belong to the exact build that created them; a newer build may not load an older state.
- Back up the whole game folder before testing an experimental build.

## Related guides

[Supported platforms](Supported-platforms) · [Discs and game data](Discs-and-game-data) · [H700 port status](H700-port-status)
