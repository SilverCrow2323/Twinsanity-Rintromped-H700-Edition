# Build guide

## Build profiles

The engine keeps desktop OpenGL as its default. H700 builds must opt in explicitly:

~~~text
-DPS2R_GLES=ON
~~~

The option is Linux-only. It selects GLES headers in both the NativeEE ExternalProject **and the top-level application/runner targets**, resolves GLESv2 and asks SDL for an OpenGL ES 3.2 context. It must not be enabled in Windows, macOS or Vita builds.

## Compile-only renderer gate

The repository includes a small standalone CMake project at porting/h700/renderer. It compiles the actual GL backend and SDL window/context source files against GLES 3.2 and SDL2 headers. It does not link a game executable or test the runtime.

Host prerequisites on Ubuntu:

~~~bash
sudo apt-get update
sudo apt-get install -y \
  g++-aarch64-linux-gnu cmake ninja-build \
  libegl1-mesa-dev libgles2-mesa-dev libsdl2-dev
~~~

Configure and compile:

~~~bash
cmake -S porting/h700/renderer -B build/h700-gles -G Ninja \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++

cmake --build build/h700-gles \
  --target h700_gles_compile_check --parallel 2
~~~

The target is called h700_gles_compile_check. A successful build means the selected engine source files compile against the installed GLES/SDL headers. It does not prove that the linked device libraries export every symbol or that the shaders render correctly.

## Full project configure

The complete TwinsanityEvolved build also uses its pinned WASI SDK and WABT toolchain for the decompiled game module. Follow the upstream toolchain setup first, then configure the root project with a real AArch64 Linux toolchain and an H700-compatible sysroot.

~~~bash
./tools/fetch_toolchain.sh

cmake -S . -B build-h700 -G Ninja \
  -DCMAKE_TOOLCHAIN_FILE=/path/to/aarch64-linux-toolchain.cmake \
  -DCMAKE_SYSROOT=/path/to/muos-sysroot \
  -DPS2R_GLES=ON \
  -DPS2R_GLES_INCLUDE_DIR=/path/to/muos-sysroot/usr/include \
  -DPS2R_GLES_LIBRARY=/path/to/muos-sysroot/usr/lib/libGLESv2.so
~~~

The sysroot must also provide the target SDL2 and FFmpeg development files required by the complete application. The root CMake project defines `PS2R_USE_GLES=1` for its own application targets, forwards the GLES option and explicit GLES header/library paths to its NativeEE ExternalProject, then links the final application to GLESv2 rather than desktop OpenGL. This keeps `runner/main.cpp` and engine translation units on the same `PS2R_GL_HEADER` selection.

The full project may require additional target-specific dependencies and configuration. The compile-only gate is intentionally independent: it can find renderer API and header incompatibilities before the complete runtime sysroot and game pipeline are ready.

## CI workflow

The H700 workflow now contains separate validation lanes:

| Job | Purpose |
|---|---|
| host-checks | Shell, probe, archive layout, launcher and host safety checks |
| gles-renderer-compile | Cross-compiles the real NativeEE renderer and SDL source objects with the ARM64 Debian GLES/SDL development headers |
| gles-shader-mesa-smoke | Builds and runs the real `GlShaderLibrary::Build()` under headless Mesa GLES 3.2; this is a blocking CI gate |
| aarch64-package | Cross-builds the EGL, SDL and NativeEE shader diagnostics, checks ELF64/AArch64 and GLIBC, then produces the diagnostic muOS `.muxapp` |
| full-app-aarch64-link | Builds and links the complete NativeEE application/runner with the H700 AArch64 toolchain and target sysroot |
| full-app-muxapp | Combines the full runner, diagnostics and FFmpeg licence/build evidence into the installable full muOS `.muxapp`; verifies ZIP integrity and the single application root |

The diagnostic package is not the game binary. The build artifact must never be described as playable until the renderer and game runtime milestones have passed.


## Verified H700 diagnostic artifact

The H700 workflow passed on commit `70a603d490a7b9977509874720551c5280bc9f43` (13 November 2026). Its artifact, `twinsanity-rintromped-h700-preflight`, contains `Twinsanity-Rintromped-H700-Preflight.muxapp` plus the three standalone ELF diagnostics. All three are ELF64/AArch64 and require at most `GLIBC_2.17` in the inspected build. The installable archive has `TwinsanityRintromped/` directly at its root and does not contain a game image.

The diagnostic package validates the hardware and production shader entry points only. It is not the full TwinsanityEvolved application and does not boot the game. For physical validation, install it using the [muOS installation guide](install.md) and collect every file under `MUOS/application/TwinsanityRintromped/logs/`, including `gles-shader-report.txt`.

## Verified full AArch64 runner and muxapp

The exact `h700/porting` HEAD `bd57d0a9ac52f0959a561b8bea03452d015331c2` passed H700 workflow run [43436273369](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43436273369) on 13 November 2026. All six jobs passed: host checks, GLES renderer compile, Mesa production shader smoke, diagnostic AArch64 package, full NativeEE application link and full muxapp package.

- Full runner: `twinsanityevolved`, ELF64/AArch64 PIE, maximum required GLIBC symbol `GLIBC_2.30` (within the Bullseye GLIBC 2.31 baseline); linked against SDL2 and GLESv2.
- Inner full `.muxapp` SHA-256: `46a06be627dfa0578e8fd0869ddea0656f2cba01a67847c37d6f28c8653f315b`.
- Actions full-muxapp artifact: ID `14043803800`, 5,560,771-byte uploaded ZIP, digest `6180ba47faee294f65a9cf2077e5921094766bd103ef08ae471f361d73b72084`.
- Full runner artifact: ID `14043129263`, 5,636,884-byte uploaded ZIP, digest `cc0571c009aa7022bc78b1796b233d3399869465fcae2720cb3a031560517fbe`.
- Preflight artifact: ID `14043388401`, 391,691-byte uploaded ZIP, digest `b5d3e2cdd082771ba6eeb6d164ace543d1517c4cb711c9b12d55a58cd40b69dc`.

The inner package passed ZIP integrity, single-root layout and licence-payload checks. It contains exactly one root, `TwinsanityRintromped/`, with `mux_launch.sh`, `mux_lang.ini`, the full AArch64 runner and diagnostics. It excludes the user's `game.iso` and `disc-image.txt`.

These are cross-build and packaging results only. The physical device has only the earlier EGL/GLES 3.2 + SDL colour-frame preflight documented above. No NativeEE first frame, game boot, controller, audio/video, disc streaming or sustained gameplay has been verified on Mali-G31.

Full package: [Actions artifact 14043803800](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43436273369/artifacts/14043803800).  
Full runner: [Actions artifact 14043129263](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43436273369/artifacts/14043129263).

## Debugging a compile failure

Record the first failing translation unit and the exact undefined type, constant or function. Classify it as one of:

- Desktop-only API requiring an adapter.
- GLES API available but missing from the current include / library setup.
- Engine dependency or generated header missing from the isolated compile project.
- Genuine source portability issue unrelated to graphics.

Do not silence errors with global macros or by substituting a desktop GL header into the GLES target.


## Production shader smoke (Mesa)

The renderer harness also exposes `h700_gles_shader_smoke_check`. It creates a headless EGL/GLES 3.2 pbuffer, instantiates the real NativeEE `GlShaderLibrary`, and compiles/links the production PS2, scanout, dither and stencil shader programs.

On Ubuntu CI:

~~~bash
sudo apt-get install -y cmake ninja-build g++ libegl1-mesa-dev libgles2-mesa-dev
cmake -S porting/h700/renderer -B build/mesa-gles -G Ninja
cmake --build build/mesa-gles --target h700_gles_shader_smoke_check --parallel 2
EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 ./build/mesa-gles/h700_gles_shader_smoke
~~~

The Mesa job is a **blocking CI gate**. A pass proves that the production shader library compiles and links under Mesa GLES; it is not proof of Mali driver behavior or correct game images. The same shader smoke is also included in the AArch64 `.muxapp` so that it can run on the physical H700. Its output is written to `logs/gles-shader-report.txt`.
