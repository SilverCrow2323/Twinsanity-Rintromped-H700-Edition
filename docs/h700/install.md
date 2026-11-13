# muOS diagnostic installation

<blockquote>
<strong>Purpose:</strong> the current .muxapp is a hardware preflight utility. It checks EGL/GLES, SDL presentation and system information. It is not the playable game.
</blockquote>

## Install

1. Download the latest successful H700 CI artifact named twinsanity-rintromped-h700-preflight.
2. Extract the artifact and copy Twinsanity-Rintromped-H700-Preflight.muxapp into the ARCHIVE folder on SD1.
3. Open **Applications → Archive Manager** in muOS.
4. Install the archive.
5. Launch **Twinsanity Rintromped** from Applications.
6. During the SDL test, the display should briefly show a sequence of solid colours.

## Archive layout

The installable archive must start at its root with the application folder. Do not wrap it in an extra application/ directory.

~~~text
TwinsanityRintromped/
├── mux_launch.sh
├── mux_lang.ini
├── tw-rintromped-h700-probe
├── tw-rintromped-h700-sdl-probe
├── tw-rintromped-h700-gles-shader-smoke
├── device/
└── logs/
~~~

## Reports

After launching, collect:

~~~text
MUOS/application/TwinsanityRintromped/logs/
├── muos-device-report.txt
├── egl-gles-report.txt
├── gles-shader-report.txt
└── sdl-window-report.txt
~~~

Attach all four reports when asking for help with a new device or a graphics failure. The shader report records the actual NativeEE production programs compiled and linked by the GLES driver; the SDL report includes the selected video driver and context result.

## Your game image remains yours

The application does not include, replace or modify game.iso. A user-provided image is separate user data. Keep a backup of it before reinstalling or replacing application files.

The diagnostic launcher currently does not parse the ISO or boot the game.
