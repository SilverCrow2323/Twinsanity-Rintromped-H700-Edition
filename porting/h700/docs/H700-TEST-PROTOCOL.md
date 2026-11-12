# H700 device test protocol

> [!IMPORTANT]
> This protocol validates the muOS userspace graphics stack and presentation path. It does not launch the game or validate the NativeEE renderer.

## 01 · Install and run

1. Download the latest successful artifact named twinsanity-rintromped-h700-preflight from the [H700 Actions runs](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions?query=branch%3Ah700%2Fporting).
2. Copy Twinsanity-Rintromped-H700-Preflight.muxapp into ARCHIVE on SD1.
3. Install it through **Applications → Archive Manager**.
4. Start **Twinsanity Rintromped** from Applications.
5. During the SDL probe, the display should show six solid-colour frames. This is a diagnostic pattern, not game footage.
6. Wait until the launcher returns to muOS.

## 02 · Collect reports

Retrieve the files from:

~~~text
MUOS/application/TwinsanityRintromped/logs/
├── muos-device-report.txt
├── egl-gles-report.txt
└── sdl-window-report.txt
~~~

| Report | What it records |
|---|---|
| muos-device-report.txt | muOS/kernel, hardware model, framebuffer/GPU/input/audio nodes, runtime libraries and environment |
| egl-gles-report.txt | EGL initialisation, vendor/version/extensions, pbuffer creation, GLES renderer/version and limits |
| sdl-window-report.txt | SDL2 library and video driver, window/context result, GLES version and buffer swaps |

## 03 · Interpret the result

| Observation | What it proves |
|---|---|
| EGL pbuffer success | Default EGL display and a small off-screen surface work |
| SDL window + swaps | SDL can create a window, obtain an ES context and present buffers |
| GLES 3.2 reported | The actual context version, not merely the requested version |
| Probe failure | A diagnostic result; retain the complete error text |

Neither report proves that the game's OpenGL 4.1 renderer, GLSL 4.10 shaders or a gameplay level works.

## 04 · Share safely

Include the three reports, device model, muOS version and package build identifier. Remove serial numbers, usernames and private filesystem paths. Never include game ISOs, saves, Wi-Fi credentials or unrelated personal logs.

## Current result · PASS

The physical H700 test supplied on 12 November 2026 passed EGL, GLES 3.2, SDL window creation and six visible buffer swaps.

The next test is the **NativeEE renderer**: compile its real source files against GLES, validate production shaders and render targets, then present the first engine-rendered frame. Follow the [build guide](../../../docs/h700/building.md) and [compatibility matrix](../../../docs/h700/compatibility-matrix.md).
