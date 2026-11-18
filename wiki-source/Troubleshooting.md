# Troubleshooting on MuOS / H700

Start with the exact package, handheld model and firmware version. Avoid changing multiple settings at once.

## The package does not appear in Archive Manager

- Confirm that the release explicitly provides a MuOS `.muxapp`.
- Follow the release's documented `ARCHIVE` destination and installation steps.
- Do not rename a different archive to `.muxapp`.

## The application does not start

- Confirm the exact H700 model and MuOS version.
- Check the package checksum against the release notes.
- Capture the error and the log path documented by that package.

## Black screen or renderer failure

- Record whether the handheld returns to MuOS, freezes or reboots.
- Include the EGL/GLES diagnostic output if the release provides it.
- Do not infer GPU support from a successful cross-build.

## Missing disc image or game data

- Check the exact filename and path stated by the MuOS release.
- Confirm that the image is a supported revision.
- Never post the image itself or copyrighted game files.

## Controls or audio do not work

- Record the physical button pressed and the expected action.
- For audio, note the output route and whether the failure is continuous or intermittent.
- Include logs and the exact build identifier.

## Still stuck?

Open an issue with the device model, MuOS version, package checksum, reproduction steps, logs and a photo of the handheld screen where useful.
