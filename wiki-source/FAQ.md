# FAQ

## Does the release include the original game?

No. The program reads your own disc image at runtime. Game data is not included in the repository or release archives.

## Can I use the Linux AArch64 archive on an H700 handheld?

Not as a supported assumption. The desktop release uses OpenGL 4.1, while the H700 needs a dedicated OpenGL ES 3.2 renderer and firmware path. See [H700 port status](H700-port-status).

## Is the PS Vita build the H700 build?

No. The PS Vita package uses its own native ARM environment and vitaGL/GXM graphics path. It is a separate target.

## Does the H700 graphics test mean the game works?

No. The physical device passed EGL, GLES 3.2 and SDL window presentation tests. The NativeEE game renderer, shaders, game boot, controls, audio and disc streaming have not yet passed on the handheld.

## Can I use a patched disc?

The mod tool can import a patched ISO or supported xdelta, PPF and BPS patches. Read [Mods](Mods) for formats and limitations.

## Where are settings and saves?

They live in the game folder. The usual folders are userdata/, memcards/ and mods/. An earlier ~/.twinsanityevolved folder continues to be used if present.

## Where are H700 logs stored?

For the diagnostic application, look in:

~~~text
MUOS/application/TwinsanityRintromped/logs/
~~~

See [Troubleshooting](Troubleshooting) for the report files to attach.

## How do I report a problem?

Include the release version, operating system or firmware, device model, disc region, reproduction steps and a short redacted log excerpt. Do not attach disc images or game data.
