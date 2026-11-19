# muOS installation — H700 Edition

<blockquote>
<strong>Current status:</strong> the physical H700 run has reached the PAL game world and loaded the beach hub. A subsequent run was terminated by the Linux OOM killer: this is a confirmed memory-pressure failure, not a confirmed GLES shader crash. The 0.2.5-dev H700 candidate now decodes textures on first draw by default, lowers retained texture-pool budgets, and reports anonymous/file-backed RSS. These changes still require a fresh on-device run before they can be called validated. This is a development build, not a release-ready installer.
</blockquote>

## Choose the package

| Artifact | What it installs | When to use it |
|---|---|---|
| `twinsanity-rintromped-h700-full-muxapp` | NativeEE runner candidate, diagnostics, launcher, reports directory and licences | **Bring-up candidate; not game-verified** |
| `twinsanity-rintromped-h700-preflight` | EGL/GLES, NativeEE shader and SDL diagnostics only | Hardware troubleshooting; it does not boot the game |

Both inner `.muxapp` files are ordinary ZIP archives renamed to `.muxapp`.

## Install the NativeEE runner candidate (not yet game-verified)

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

## Recommended test image

For repeatable H700 testing, use the **PAL edition** of Crash Twinsanity as the reference disc image. PAL uses a 50 Hz video timing standard, which is the baseline used by the current device run. That does **not** mean the H700 port is already rendering at 50 FPS: actual frame rate and frame pacing depend on the unfinished renderer and its current performance limits.

The project distributes neither the disc image nor copyrighted game data. Supply your own legally obtained image; the PAL recommendation is about a consistent test baseline, not a bundled or modified ROM.

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

## Device validation sequence

Use the two packages for different acceptance gates; they are not interchangeable.

### A. Physical EGL / Mali shader / SDL preflight

1. Install the `twinsanity-rintromped-h700-preflight` artifact through Archive Manager as described above.
2. Launch **Twinsanity Rintromped** once. The SDL probe displays six solid-colour frames; this is a presentation diagnostic, not game footage.
3. Wait for the application to return to muOS, then copy the four reports listed below.
4. Record the preflight artifact's workflow run, commit SHA and inner `.muxapp` SHA-256.

The shader report exercises the selected NativeEE production shader programs on the actual Mali GLES context. A successful compile/link report does not prove GS surfaces, draw submission, final image correctness or gameplay.

### B. Full NativeEE runner / game boot

1. Install the `twinsanity-rintromped-h700-full-muxapp` artifact. Extract only the outer GitHub Actions artifact ZIP; keep the inner `.muxapp` intact and verify its adjacent `.sha256` sidecar.
2. Put your own disc image at `MUOS/application/TwinsanityRintromped/game.iso`. The image is not part of either artifact.
3. Launch the installed application. The full package selects `twinsanityevolved`, defaults SDL to the muOS `mali` video driver unless overridden, and invokes the standalone runner with the resolved `--iso <path>` argument. The current runner does not include the separate ImGui launcher UI, so no `--launcher` flag is passed.
4. Observe and report separately: runner starts, first NativeEE-rendered frame appears, game reaches gameplay, controller/audio/video work, and sustained play is stable.
5. Copy `logs/game-launch.log`. The first installed launch also consumes the one-shot performance diagnostics marker and writes the profiler output into the game launch log. For another capture, create an empty `logs/performance-diagnostics.once` before launching again.
6. Record the full artifact workflow run, exact source commit SHA, inner `.muxapp` SHA-256, muOS version and device model.

Do not upload the ISO, saves, serial numbers, usernames, Wi-Fi credentials or unrelated personal logs.

## Reports and troubleshooting

The reports live under:

```text
MUOS/application/TwinsanityRintromped/logs/
├── muos-device-report.txt
├── egl-gles-report.txt
├── gles-shader-report.txt
├── sdl-window-report.txt
└── game-launch.log
```

The first four files are generated by the diagnostic-only preflight. `game-launch.log` is generated by the full runner path and captures startup details, runner output and the one-shot performance diagnostics when enabled.

| Report | What it records |
|---|---|
| muos-device-report.txt | muOS/kernel, hardware model, framebuffer/GPU/input/audio nodes, runtime libraries and environment |
| egl-gles-report.txt | EGL initialisation, vendor/version/extensions, pbuffer creation, GLES renderer/version and limits |
| gles-shader-report.txt | NativeEE production shader program IDs, compile/link status, and driver diagnostics |
| sdl-window-report.txt | SDL2 library and video driver, window/context result, GLES version and buffer swaps |
| game-launch.log | Selected disc path, SDL driver, muOS handoff details, NativeEE startup output and one-shot performance diagnostics |

Attach the preflight reports for graphics-driver failures and the full runner log for startup/boot failures. Never treat the six-colour SDL diagnostic as a NativeEE frame or gameplay.

## Validation boundary

CI has verified cross-compilation, production shader compilation/link on Mesa, AArch64 architecture, GLIBC baseline, the static LGPL FFmpeg configuration and the ZIP package layout. The physical report supplied for the current PAL run confirms that the game entered the beach hub (`levels/earth/hub/beach`); the kernel later killed `te-game` for out-of-memory pressure (approximately 706 MiB file-backed RSS plus 127 MiB anonymous RSS at termination). The cause within those resident mappings is still under investigation. Sustained play, stable memory usage and useful frame pacing are not yet verified on the physical H700.
