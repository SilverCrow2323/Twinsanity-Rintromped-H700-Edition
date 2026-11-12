# Troubleshooting

Start with the exact message shown by the launcher or game. Keep the original error text before changing settings.

## 💿 The game does not recognise my disc

- Confirm that the selected file is your own Crash Twinsanity ISO.
- Check whether it is the documented PAL or North American disc.
- A modified image may be labelled as modified.
- Do not patch or rename an image just to make its filename look like a known disc.

## 🧩 A mod is missing

- Check that the mod is enabled in the launcher's **Mods** page.
- Check the disc-region badge and any warning that a mod was skipped.
- Restart the game after changing the mod list.
- Verify the mod with **twinsanityevolved-modtool verify** and your own disc image.

## 💾 A save state will not load

Save states belong to the exact build that created them. Try a memory-card save instead; memory-card saves are stored separately.

Back up your game folder before testing another build.

## 🖥️ Desktop graphics are unavailable

The current desktop release notes specify an OpenGL 4.1 driver. Update the vendor driver where appropriate and check that your hardware meets the requirement.

An H700 handheld uses a separate GLES path. Do not assume that a desktop Linux AArch64 binary will work there; see [H700 port status](H700-port-status).

## 📟 H700 diagnostic app does not show colour frames

Check sdl-window-report.txt in the diagnostic application's logs directory. Look for:

- The selected SDL video driver.
- The result of SDL window creation.
- The OpenGL ES context version.
- Any GLES error reported after a buffer swap.

A pbuffer PASS alone does not prove that a visible SDL window works. The dedicated SDL test checks that separate stage.

## 🧾 What to include in a report

- Release version and exact asset name.
- Operating system, firmware and device model.
- Disc region: PAL, North American or modified.
- Steps to reproduce and the full relevant log excerpt.
- Whether the issue also occurs with mods disabled.

> [!IMPORTANT]
> Never attach a disc image, copyrighted game files, access tokens or private device data to a public report.
