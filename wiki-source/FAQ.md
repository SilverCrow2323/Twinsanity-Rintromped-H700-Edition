# FAQ

## Does the release include the original game?

No. The program reads your own disc image at run time. Game data is not included in the repository or release archives.

## Can I use the Linux AArch64 archive on an H700 handheld?

Not as a supported assumption. The current desktop release notes specify OpenGL 4.1, while the H700 target needs a device-specific graphics and firmware path. See [H700 port status](H700-port-status).

## Is the PS Vita build the H700 build?

No. The PS Vita package is built for the Vita's native ARM environment and graphics path. It is a separate target.

## Why does a save state from an older release fail?

Save states belong to the build that created them. Memory-card saves are stored separately and are not the same thing.

## Can I use a patched disc?

The mod tool can import a patched ISO or supported xdelta / PPF / BPS patches. Read [Mods](Mods) for the supported formats and limitations.

## Where are settings and saves?

They live in the game folder, with `userdata/`, `memcards/` and `mods/` kept beside the program. An earlier `~/.twinsanityevolved` folder continues to be used if present.

## How do I report a problem?

Include the release version, operating system or firmware, device, disc region, steps to reproduce and a short redacted log excerpt. Do not attach disc images or game data.
