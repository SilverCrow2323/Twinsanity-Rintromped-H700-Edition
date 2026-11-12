# Troubleshooting

Start with the exact message shown by the launcher or game. Keep the original error text in your notes before changing settings.

## The game does not recognise my disc

- Confirm that the selected file is your own Crash Twinsanity disc image in ISO format.
- Check whether it is the documented PAL or North American disc.
- If the image is modified, the launcher may label it as a modified disc.
- Avoid renaming or patching the image just to make its filename look like a known disc.

## The game starts but a mod is missing

- Check that the mod is switched on in the launcher's **Mods** page.
- Check the disc-region badge and any warning that says the mod was left out.
- Remember that a mod change takes effect after restarting the game.
- Verify the mod with `twinsanityevolved-modtool verify` and your own disc image.

## A save state will not load

- Save states belong to the exact build that created them.
- Try a memory-card save instead; memory-card saves are separate from save states.
- Back up the game folder before testing another build.

## Desktop graphics are unavailable

- Check that the graphics driver meets the desktop OpenGL 4.1 requirement documented by the release notes.
- Update the vendor driver where appropriate.
- On an H700 handheld, do not assume that a desktop Linux AArch64 binary will work; check [H700 port status](H700-port-status).

## What to include in a report

- Release version and asset name.
- Operating system, firmware and device model.
- Whether the disc is PAL, North American or modified.
- The exact steps before the issue and the full relevant log excerpt.
- A note about whether the issue also happens with mods disabled.

> **MUST KNOW!!** Never attach a disc image, copyrighted game files, account tokens or private device data to a public report.

---
