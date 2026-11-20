# H700 physical-device acceptance protocol

This procedure separates three different results: (1) EGL/GLES/SDL preflight, (2) production NativeEE shader and first-frame validation on Mali, and (3) actual game boot and sustained gameplay. A successful preflight or Mesa CI smoke is not a gameplay result.

## Tested package

Latest complete H700 CI code build: [run #310](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315), code commit `681f0b3249cbb4e3f900ff55db4db252c949e3e3`. All six jobs passed: host checks, GLES renderer compile, blocking Mesa shader smoke, full AArch64 link, diagnostic package and full muxapp package.

NativeEE runner-candidate artifact: [full muxapp artifact](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315/artifacts/14214608053), artifact ID `14214608053`. Inner `.muxapp` SHA-256:

```text
f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53
```

Outer Actions ZIP digest: `3a53eed01fd3e43583bb13b3758aafd48b5800ce1fecc61c32b01353d5b5d8e9`. The archive has one `TwinsanityRintromped/` root, an ELF64/AArch64 `twinsanityevolved` runner, launcher, diagnostics and licences. It contains neither `game.iso` nor `disc-image.txt`.

**Build boundary:** CI had no title ELF or disc input; title-specific recompilation, game composition and title-dependent EE/CDVD tests were skipped. This is a runner candidate, not a game-verified build.

The separate [preflight artifact](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43434846948/artifacts/14043651388) is diagnostic-only and does not contain the game runner. Its six-colour SDL display is not a NativeEE frame.

## Stage A — EGL / GLES / SDL preflight

1. Download the `twinsanity-rintromped-h700-preflight` Actions artifact.
2. Extract the outer GitHub Actions ZIP once. Copy the inner `Twinsanity-Rintromped-H700-Preflight.muxapp` into `ARCHIVE` on SD1.
3. Install it through **Applications → Archive Manager** and launch **Twinsanity Rintromped**.
4. The SDL probe should display six solid-colour frames. This is a diagnostic pattern, not game footage.
5. Wait for muOS to return, then retrieve these files from `MUOS/application/TwinsanityRintromped/logs/`:

| Report | What it records |
|---|---|
| `muos-device-report.txt` | muOS/kernel, model, framebuffer/GPU/input/audio nodes, runtime libraries and environment |
| `egl-gles-report.txt` | EGL initialisation, vendor/version/extensions, pbuffer, GLES renderer/version and limits |
| `gles-shader-report.txt` | NativeEE production shader IDs, compile/link status and driver diagnostics |
| `sdl-window-report.txt` | SDL library/video driver, window/context result, GLES version and buffer swaps |

A successful pbuffer proves only a small EGL off-screen surface works. SDL window + swaps prove SDL can create a window, obtain an ES context and present buffers. A successful shader report proves only that the selected programs compile/link in that device context; it does not prove GS surface correctness or gameplay.

## Stage B — full NativeEE runner and game boot

1. Extract only the outer GitHub Actions artifact ZIP.
2. Verify the inner `.muxapp` using the adjacent `.sha256` sidecar. Do not extract the inner `.muxapp` or wrap it in another archive.
3. Copy `Twinsanity-Rintromped-H700-Edition.muxapp` into `ARCHIVE` on SD1 and install via **Applications → Archive Manager**.
4. Put your own disc image at:

```text
MUOS/application/TwinsanityRintromped/game.iso
```

Do not rename or nest the application folder. The ISO is user-supplied and is never part of the package.
5. Launch **Twinsanity Rintromped** from Applications.

When the full runner is present, `mux_launch.sh` selects `twinsanityevolved`, resolves the saved disc selection or seeds it from `game.iso`, defaults `SDL_VIDEODRIVER` to `mali` when unset, and runs `twinsanityevolved --iso <path> --launcher`. Startup output and stderr are appended to `logs/game-launch.log`.

Record these checkpoints separately:

- muOS application entry starts and hands control to the runner;
- runner creates an EGL/GLES/SDL context;
- production NativeEE shaders compile/link on Mali;
- GS colour/depth/stencil surfaces, textures, mipmaps, copies and readback work;
- first NativeEE-rendered game frame appears;
- game reaches a playable state;
- controller, audio, video/cutscenes, disc streaming and saves work;
- sustained play is stable; frame pacing, stutter and thermals are measured.

The first full-runner launch consumes `logs/performance-diagnostics.once` and enables a low-overhead one-shot profiler. To request another capture, create an empty file at that path before launching again. Retrieve `MUOS/application/TwinsanityRintromped/logs/game-launch.log` with the four device reports when available.

## Share the result safely

Provide the exact package SHA-256 and Actions run/artifact ID, device model and muOS version/build, whether this was Stage A or B, the highest checkpoint reached, and the relevant reports/logs. Remove serial numbers, usernames, private paths and unrelated personal logs. Never upload the ISO, saves, Wi-Fi credentials or other private data.

## Existing evidence and current boundary

A physical H700 test supplied on 12 November 2026 passed EGL 1.4, GLES 3.2, SDL window creation and six visible buffer swaps on muOS 2606.0 Andromeda / Allwinner sun50iw9 / Mali-G31. This is Stage A preflight evidence.

A separate physical bring-up report dated 13 November 2026 records an earlier runner launch with the user's PAL `SLES-52568` image: the launcher passed `--iso`, NativeEE loaded the retail ELF, initialised the muOS gamepad and SDL audio, and created an ES 3.2 context on Mali-G31. The first PS2 vertex shader then failed on a leading newline before `#version`. The shader normaliser was subsequently fixed and Mesa CI now passes, but no post-fix Mali retest is documented. That 13 November report does not include an exact firmware build, package SHA-256 or Actions artifact ID.

CI run #310 passed AArch64 renderer compile, Mesa llvmpipe production-shader smoke, NativeEE runner link and full `.muxapp` packaging. Mesa is a software renderer, not Mali. The CI build had no title ELF/disc input, so title-specific recompilation and game composition were skipped. Mali production shaders, GS surfaces, the first NativeEE frame and gameplay remain pending.

See the [installation guide](../../../docs/h700/install.md), [graphics port](../../../docs/h700/graphics-port.md) and [compatibility matrix](../../../docs/h700/compatibility-matrix.md).
