# H700 device test protocol

This milestone validates the userspace graphics stack and the muOS presentation path only. It does not launch the game.

## Install and run

1. Download the latest successful twinsanity-rintromped-h700-preflight artifact from the [H700 Actions runs](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions?query=branch%3Ah700%2Fporting).
2. Copy Twinsanity-Rintromped-H700-Preflight.muxapp into the ARCHIVE folder on SD1.
3. Install it through **Applications → Archive Manager**.
4. Start **Twinsanity Rintromped** from Applications.
5. The SDL probe should show a short sequence of six solid-colour frames. This is a diagnostic pattern, not game footage.
6. Wait until the launcher returns to muOS.

## Collect the reports

Retrieve these files from MUOS/application/TwinsanityRintromped/logs/:

| Report | What it records |
|---|---|
| muos-device-report.txt | muOS/kernel, device model, framebuffer/GPU/input/audio nodes, runtime libraries and display environment |
| egl-gles-report.txt | EGL initialisation, EGL vendor/version/extensions, pbuffer creation, GLES vendor/renderer/version and selected limits |
| sdl-window-report.txt | SDL2 library and video driver, SDL window creation, requested context attributes, GLES version and colour-buffer swaps |

## How to interpret results

- EGL pbuffer success proves only that the default EGL display and a small off-screen surface work.
- SDL window + swap success proves that the SDL video driver can create a window, obtain an ES context and present buffers.
- Neither report proves that the game's OpenGL 4.1 renderer, GLSL 4.10 shaders or any gameplay level works.
- A missing library or unavailable video driver is useful diagnostic evidence; keep the full error text.
- Do not infer GLES 3.2 support from a request alone. Read the actual GL_VERSION string in the report.

## Share safely

Share only these three reports, the device model, muOS version and package build identifier. Remove serial numbers, usernames and private filesystem paths when present. Do not include game ISOs, saves, Wi-Fi credentials or unrelated logs.
