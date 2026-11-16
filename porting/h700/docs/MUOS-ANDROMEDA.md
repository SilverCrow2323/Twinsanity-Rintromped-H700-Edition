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

The full-game package never contains a disc image. Put your own `game.iso` directly in the installed `TwinsanityRintromped/` application folder; the launcher passes the selected image to NativeEE with `--iso`. A saved `disc-image.txt` selection may point to a file inside that application root, including a subfolder, but absolute paths outside the root, parent-directory escapes and symlink escapes are rejected. If the saved selection is missing or unsafe, the launcher falls back to the root-level `game.iso` and repairs the selection file. A symlinked `game.iso` is not accepted.

The ISO remains user data: it is never copied into the .muxapp. Back it up before reinstalling an archive because Archive Manager is not guaranteed to preserve files that are not part of the package.

## References

- [muOS Application Runner](https://community.muos.dev/t/application-runner/1282)
- [Manually creating installable archives](https://community.muos.dev/t/manually-creating-installable-archives/824)
- [muOS MuxApp tour](https://muos.dev/tour/modules/muxapp)
- [Player installation guide](../../../docs/h700/install.md)
