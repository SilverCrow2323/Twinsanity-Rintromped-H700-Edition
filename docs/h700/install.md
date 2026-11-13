# muOS installation — H700 Edition

<blockquote>
<strong>Current candidate:</strong> the full-game H700 `.muxapp` is built by CI for AArch64 and uses the device's SDL2, EGL and GLES runtime. FFmpeg's required MPEG-1/2 decode path is linked statically with the minimal LGPL recipe. The first launch on physical Mali-G31 is still a device-validation step, not a CI-proven gameplay result.
</blockquote>

## Choose the package

| Artifact | What it installs | When to use it |
|---|---|---|
| `twinsanity-rintromped-h700-full-muxapp` | Game runner, diagnostics, launcher, reports directory and licences | **Normal installation / game candidate** |
| `twinsanity-rintromped-h700-preflight` | EGL/GLES, NativeEE shader and SDL diagnostics only | Hardware troubleshooting; it does not boot the game |

Both inner `.muxapp` files are ordinary ZIP archives renamed to `.muxapp`.

## Install the full-game candidate

1. Open the latest successful **Twinsanity Rintromped H700** workflow and download the artifact `twinsanity-rintromped-h700-full-muxapp`.
2. Extract the outer GitHub Actions artifact ZIP once. Inside it you will find `Twinsanity-Rintromped-H700-Edition.muxapp` and its `.sha256` file.
3. Verify the checksum when possible. Keep the inner `.muxapp` extension; do **not** extract it or wrap it in a second archive.
4. Copy the `.muxapp` into the `ARCHIVE` folder on SD1.
5. Open **Applications → Archive Manager** in muOS and install it.
6. Launch **Twinsanity Rintromped** from Applications.

The installed application expects your own disc image at:

```text
MUOS/application/TwinsanityRintromped/game.iso
```

The launcher selects `game.iso` only when there is no valid existing `disc-image.txt` selection. It does not rewrite, patch, or bundle the ISO. Keep a separate backup of your disc image and saves before installing or updating the application.

## Archive layout

The full-game archive starts directly at the application folder. There is no extra wrapper directory.

```text
TwinsanityRintromped/
├── twinsanityevolved
├── mux_launch.sh
├── mux_lang.ini
├── README.txt
├── RELEASE-NOTES.txt
├── tw-rintromped-h700-probe
├── tw-rintromped-h700-sdl-probe
├── tw-rintromped-h700-gles-shader-smoke
├── device/
├── licenses/
└── logs/
```

The runner is AArch64 ELF64 and is built against the Bullseye-compatible GLIBC baseline (maximum required symbol checked by CI: GLIBC 2.30). It links to the device's SDL2/GLES runtime. FFmpeg's MPEG-1/2 decoder, MPEG parser and swscale are statically linked; the LGPL texts and exact build configuration are included in `licenses/`.

## Diagnostic-only preflight

For hardware diagnostics, download `twinsanity-rintromped-h700-preflight`, extract the outer Actions ZIP once, and install the contained `Twinsanity-Rintromped-H700-Preflight.muxapp` through Archive Manager. This package does **not** contain the game runner and does not parse or boot `game.iso`.

## Reports and troubleshooting

Game launch output is written to:

```text
MUOS/application/TwinsanityRintromped/logs/game-launch.log
```

The diagnostic-only preflight writes:

```text
MUOS/application/TwinsanityRintromped/logs/
├── muos-device-report.txt
├── egl-gles-report.txt
├── gles-shader-report.txt
└── sdl-window-report.txt
```

Attach the game log when the game does not start. For a renderer or driver problem, install/run the diagnostic preflight and attach all four reports. In particular, `gles-shader-report.txt` records the actual NativeEE production shader programs compiled and linked by the GLES driver.

## Validation boundary

CI has verified cross-compilation, production shader compilation/link on Mesa, AArch64 architecture, GLIBC baseline, the static LGPL FFmpeg configuration and the ZIP package layout. It has **not** verified a full game boot, Mali-specific shader compatibility, gameplay, audio, controller behavior or sustained frame pacing on the physical H700. Those remain the release-candidate device tests.
