# Mods

Mods change files the game reads from your disc. They do not replace the port's executable code or rewrite your original disc image.

## Supported inputs

The current README documents these import paths:

- Mod Crates (`.zip` or a folder containing `ModCrateInfo.txt`, `layer0/` and `layer1/`).
- A patched disc image (`.iso`).
- xdelta, PPF and BPS patches made against the original disc.
- A folder of files laid out like the disc, or a folder already containing a supported `mod.json`.
- A single file from the game's archive when its name identifies one unambiguous entry.

Import mods from the launcher's **Mods** page or with `twinsanityevolved-modtool`.

## Enable and order mods

1. Add the mod using the launcher or mod tool.
2. Open the launcher's **Mods** page.
3. Switch the mod on.
4. Drag mods into the desired order; the lower mod wins when two mods change the same file.
5. Restart the game for the change to take effect.

## Important limits

- Code changes inside a modified executable are not applied.
- `ModCrateSettings.txt` and crates with scripts are not supported.
- xdelta patches using secondary compression modes listed in the README are refused; apply them yourself and import the patched disc image instead.
- RAR / 7-Zip archives, CHD / CSO / ECM images, CUE sheets, UPS / IPS patches, encrypted ZIPs, emulator texture packs and cheat codes are not supported by this importer.

## Disc compatibility

Mods record the files they were made against. A mod made for a different regional disc may be left out at game start. Read the launcher warning before assuming a mod is active.

## Related pages

- [Discs and game data](Discs-and-game-data)
- [Troubleshooting](Troubleshooting)
