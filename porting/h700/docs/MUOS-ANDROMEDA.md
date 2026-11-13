# muOS Andromeda · Application integration

> [!IMPORTANT]
> The installable archive root must start directly with **TwinsanityRintromped/**. Do not wrap it in an extra application/ directory. Keep a backup of any user-provided game.iso before reinstalling an application archive.

## 📦 Package layout

~~~text
TwinsanityRintromped/
├── mux_launch.sh
├── mux_lang.ini
├── tw-rintromped-h700-probe
├── tw-rintromped-h700-sdl-probe
├── device/
└── logs/
~~~

The launcher follows the muOS Application Runner contract for muOS 2601/2606:

- Source /opt/muos/script/var/func.sh.
- Call SETUP_APP for the executable.
- Use the bind-mounted path /run/muos/storage/application/TwinsanityRintromped.

A .muxapp is a ZIP archive with a different extension. Copy it into ARCHIVE on SD1, then install it using **Applications → Archive Manager**.

## 🔍 Diagnostic flow

~~~mermaid
flowchart TD
    A["muOS starts app"] --> B["Collect system information"]
    B --> C["EGL / GLES pbuffer probe"]
    C --> D["SDL / GLES window probe"]
    D --> E["Write diagnostic reports"]
    E --> F["Return to muOS"]
~~~

| Step | Program | Report |
|---|---|---|
| 1 | collect-system-info.sh | muos-device-report.txt |
| 2 | tw-rintromped-h700-probe | egl-gles-report.txt |
| 3 | tw-rintromped-h700-sdl-probe | sdl-window-report.txt |

A graphics capability failure is written to the reports. The launcher then returns to muOS rather than treating an unavailable graphics feature as an application-runner failure.

## User data stays separate

The diagnostic application does not include, replace, open or validate game.iso. Keep the image as user data in the application folder and make a backup before reinstalling an archive. Do not assume Archive Manager preserves files that are not part of the new package.

## References

- [muOS Application Runner](https://community.muos.dev/t/application-runner/1282)
- [Manually creating installable archives](https://community.muos.dev/t/manually-creating-installable-archives/824)
- [muOS MuxApp tour](https://muos.dev/tour/modules/muxapp)
- [Player installation guide](../../../docs/h700/install.md)
