# FAQ & troubleshooting

## Is the H700 graphics hardware supported?

The tested muOS Andromeda device successfully initialised EGL 1.4 and GLES 3.2 on its Mali-G31. SDL also created a window and presented six visible frames using the mali video driver. This is a strong graphics preflight result, not a guarantee that every H700 device or every engine feature behaves identically.

## Does the game run already?

No. The physical tests are diagnostics. The NativeEE renderer still needs GLES compilation, shader validation, render-target verification and a first engine-rendered frame before game boot work can be considered.

## Can I use game.iso?

The diagnostic application does not read it yet. You can keep your image in the application data folder, but the current probe does not open or validate it.

## Why does the build use a dedicated PS2R_GLES option?

AArch64 does not imply OpenGL ES. The option explicitly chooses GLES headers and libraries and leaves desktop builds on their existing OpenGL path.

## Why is the GPU timer overlay disabled on GLES?

The device advertises GL_EXT_disjoint_timer_query, but the desktop timer implementation cannot be assumed to use the extension correctly. The first profile disables it until a GLES-specific implementation is added and validated.

## The app launches but the screen does not flash through colours

Check sdl-window-report.txt. Look for the SDL video driver, SDL_GL_CreateContext result and buffer-swap errors. A pbuffer PASS alone does not guarantee window presentation; the SDL probe is the relevant check for this symptom.

## Where do I find the logs?

They are stored in:

~~~text
MUOS/application/TwinsanityRintromped/logs/
~~~

## Can I submit an issue without the logs?

You can, but include the device model, muOS version, kernel and the exact last successful or failed stage. Logs make graphics failures substantially easier to classify.

## Are game files distributed with this repository?

No. No game ISO, firmware blobs or copyrighted game assets are bundled in the source tree or diagnostic archive.
