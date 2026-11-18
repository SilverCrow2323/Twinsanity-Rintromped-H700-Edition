# Getting started on MuOS

This guide covers Twinsanity Evolved on an Allwinner H700 handheld running MuOS. Install only a release explicitly marked as a playable MuOS / H700 package.

> [!IMPORTANT]
> The current H700 preflight package is diagnostic, not a playable game build. If the Releases page does not contain a playable MuOS package with device validation notes, stop here and do not install the preflight expecting gameplay.

## Before you start

- Confirm the exact H700 handheld model and installed MuOS version.
- Back up your SD card, saves and personal configuration.
- Have your own legally obtained Crash Twinsanity disc image ready.
- Read the package-specific prerequisites and checksum on the release page.

## Install a MuOS package

1. Open the project's [Releases](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/releases).
2. Select an artifact explicitly labelled for MuOS / H700 and read its release notes.
3. If the release supplies a `.muxapp`, follow its exact instructions for placing it in the MuOS `ARCHIVE` folder and installing it through Applications → Archive Manager.
4. Follow the release's documented game-data path and first-launch steps exactly.
5. Keep a backup of personal data before updating or removing an experimental build.

Do not rename another archive to `.muxapp`, copy runtime files from another target onto the handheld or guess paths that are not documented by the release.

## Data and saves

The final MuOS package documentation must state the exact location of the user-owned disc image, settings, memory cards and logs. Until those paths are confirmed on hardware, do not assume a path from another target.

## Related pages

- [Supported target](Supported-platforms)
- [Discs and game data](Discs-and-game-data)
- [H700 port status](H700-port-status)
- [Troubleshooting](Troubleshooting)
