# H700 device test protocol

This milestone validates the userspace graphics stack and package layout only; it does not launch the game.

1. Install the CI artifact Twinsanity-Rintromped-H700-Preflight.muxapp through Archive Manager.
2. Start Twinsanity Rintromped from Applications.
3. Wait for the probe to finish. A missing EGL default display can still produce a useful report; it means a later SDL-owned EGL test is required.
4. Retrieve egl-gles-report.txt and muos-device-report.txt from MUOS/application/TwinsanityRintromped/logs/.
5. Review EGL vendor/version, GLES vendor/renderer/version, extensions, limits, firmware/kernel, framebuffer and graphics device nodes.
6. Do not infer complete renderer compatibility from successful context creation. Upstream also uses desktop-only APIs and GLSL 4.10.

Do not include game ISOs, saves, personal files, Wi-Fi credentials or unrelated logs in reports.
