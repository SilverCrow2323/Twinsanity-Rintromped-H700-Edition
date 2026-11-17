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

The current `h700/porting` HEAD `681f0b3249cbb4e3f900ff55db4db252c949e3e3` passed H700 workflow run [`43844953315`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/43844953315) on 16 November 2026. All six jobs passed: host checks, AArch64 renderer compile, blocking Mesa production shader smoke, full application link, diagnostic package and full muxapp package.

- Full runner: `twinsanityevolved`, ELF64 little-endian AArch64 PIE; maximum required GLIBC symbol `GLIBC_2.30` (within the pinned Bullseye GLIBC 2.31 baseline).
- Full package: `Twinsanity-Rintromped-H700-Edition.muxapp`; inner SHA-256 `f243a70cd66cdcab65f2cbc1dd8f1750536bbb21dfb31a4c388ef35369b54e53`.
- Full-muxapp Actions artifact: ID `14214608053`, outer ZIP size 5,561,027 bytes, digest `3a53eed01fd3e43583bb13b3758aafd48b5800ce1fecc61c32b01353d5b5d8e9`.
- Full-runner Actions artifact: ID `14215381134`, outer ZIP size 5,636,884 bytes, digest `7232c57f5c89a663369009346481e6a8e8dcbeeada0531e9286d704e07aa5ac2`.
- The package contains exactly one root, `TwinsanityRintromped/`, with `mux_launch.sh` and `mux_lang.ini`; it excludes the user's `game.iso` and `disc-image.txt`.

**Build boundary:** this CI run had no title ELF or disc input. The title recompilation, game composition and title-dependent EE/CDVD tests were skipped. The generic runner link and full package are not proof of a first NativeEE frame or playable game.

The Mesa smoke is a blocking software-renderer shader compile/link test only. Mali shader execution, render targets, depth/stencil, texture upload/readback, first NativeEE frame, game boot and sustained gameplay remain physical-device gates.

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
