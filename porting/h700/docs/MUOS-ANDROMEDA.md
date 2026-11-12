# muOS Andromeda application integration

The launcher follows the muOS Application Runner contract for muOS 2601/2606: source func.sh, call SETUP_APP, and use the bind-mounted path /run/muos/storage/application/TwinsanityRintromped. The installable archive root starts directly with TwinsanityRintromped/; it has no enclosing application/ directory.

The .muxapp is a ZIP archive with a different extension. Install it from ARCHIVE using **Applications → Archive Manager**.

## Diagnostic flow

The launcher runs three steps:

1. collect-system-info.sh writes the muOS/kernel and device inventory.
2. tw-rintromped-h700-probe tests EGL initialisation and an off-screen GLES pbuffer.
3. tw-rintromped-h700-sdl-probe asks SDL2 for an ES 3.2 context, creates a window and swaps six colour frames.

Each report is saved in MUOS/application/TwinsanityRintromped/logs/:

- muos-device-report.txt
- egl-gles-report.txt
- sdl-window-report.txt

A graphics capability failure is recorded in the reports; the launcher returns to the muOS menu instead of treating a missing GLES feature as a launcher crash. Passing both probes does not mean the game renderer is ported.

## References

- https://community.muos.dev/t/application-runner/1282
- https://community.muos.dev/t/manually-creating-installable-archives/824
- https://muos.dev/tour/modules/muxapp
