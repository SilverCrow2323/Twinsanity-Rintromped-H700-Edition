# muOS Andromeda application integration

The launcher follows the official Application Runner contract for muOS 2601/2606: source func.sh, call SETUP_APP, and use the bind-mounted path /run/muos/storage/application/TwinsanityRintromped. The installable archive uses application/ as its top-level directory.

The .muxapp is a ZIP archive with a different extension. Install it from ARCHIVE using Applications → Archive Manager.

The first package is diagnostic only. Its executable writes logs/egl-gles-report.txt and the launcher writes logs/muos-device-report.txt in the installed application folder.

References:
- https://community.muos.dev/t/application-runner/1282
- https://community.muos.dev/t/manually-creating-installable-archives/824
- https://muos.dev/tour/modules/muxapp
