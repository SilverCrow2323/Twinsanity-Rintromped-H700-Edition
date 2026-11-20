# Mods

Mods change files the game reads from your disc. They do not replace the port executable or rewrite your original disc image.

## 📦 Supported inputs

The current importer documents these formats:

- Mod Crates: ZIP files or a folder containing ModCrateInfo.txt, layer0/ and layer1/.
- A patched disc image: ISO.
- xdelta, PPF and BPS patches made against the original disc.
- A folder laid out like the disc, or a folder containing a supported mod.json.
- A single file from the game archive when its name identifies one unambiguous entry.

Import mods from the launcher's **Mods** page or with **twinsanityevolved-modtool**.

## ⚙️ Enable and order mods

1. Add the mod through the launcher or mod tool.
2. Open the launcher's **Mods** page.
3. Switch the mod on.
4. Drag mods into the desired order.
5. Restart the game to apply the change.

When two mods change the same file, the lower mod in the list wins.

## ⚠️ Important limits

- Code changes inside a modified executable are not applied.
- ModCrateSettings.txt and crates with scripts are not supported.
- Some xdelta secondary-compression modes are refused; apply those patches yourself and import the patched ISO.
- RAR / 7-Zip archives, CHD / CSO / ECM images, CUE sheets, UPS / IPS patches, encrypted ZIPs, emulator texture packs and cheat codes are not supported by this importer.

## Disc compatibility

Mods record the files they were made against. A mod built for another regional disc may be skipped when the game starts. Read the launcher's warning before assuming a mod is active.

## Related guides

[Discs and game data](Discs-and-game-data) · [Troubleshooting](Troubleshooting)
