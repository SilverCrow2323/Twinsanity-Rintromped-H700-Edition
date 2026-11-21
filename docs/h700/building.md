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

The current validated H700 code HEAD `95732802bd5c651e83a90dfdf85d95249b3654aa` passed workflow run [`44067269456`](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44067269456) on 17 November 2026. All six jobs passed: host checks, AArch64 renderer compile, blocking Mesa production shader smoke, full application link, diagnostic package and full muxapp package.

- Full runner: `twinsanityevolved`, ELF64 little-endian AArch64 PIE; maximum required GLIBC symbol `GLIBC_2.30` (within the pinned Bullseye GLIBC 2.31 baseline).
- Full package: `Twinsanity-Rintromped-H700-Edition.muxapp`; inner SHA-256 `a088feba52ec205c558bb1918f66de041510b23981f5865abdaeb89ae51c08a3`.
- Full-muxapp Actions artifact: ID `14321467319`, outer ZIP size 5,565,674 bytes, digest `d59fe6940c0448086a945f665c7c7470d1ab5086cc955f2652205df7471d02f9`.
- Full-runner Actions artifact: ID `14321691939`, outer ZIP size 5,644,398 bytes, digest `7d3a89630d053dc9030fa1253c13ba186ea6835927545d18ce1fc06a7cbdb29e`.
- The package job verified ZIP integrity, the single root `TwinsanityRintromped/`, diagnostics and licence payload; the user's `game.iso` and `disc-image.txt` are excluded.

The generic NativeEE runner was built without a title ELF or disc image. This is a full link/package milestone, not proof of a first game frame or playable runtime.

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

The renderer harness also exposes `h700_gles_shader_smoke_check`. It creates a headless EGL/GLES 3.2 pbuffer, instantiates the real NativeEE `GlShaderLibrary`, and compiles/links the production PS2, scanout, dither and stencil shader programs. It then checks an RGBA8 color target with a DEPTH24_STENCIL8 attachment, uploads a known texture, generates its mip chain, blits between framebuffer objects and reads pixels back.

On Ubuntu CI:

~~~bash
sudo apt-get install -y cmake ninja-build g++ libegl1-mesa-dev libgles2-mesa-dev
cmake -S porting/h700/renderer -B build/mesa-gles -G Ninja
cmake --build build/mesa-gles --target h700_gles_shader_smoke_check --parallel 2
EGL_PLATFORM=surfaceless LIBGL_ALWAYS_SOFTWARE=1 ./build/mesa-gles/h700_gles_shader_smoke
~~~

The Mesa job is a **blocking CI gate**. A pass proves that the production shader library compiles/links and that the basic color/depth-stencil FBO, upload/mipmap, blit and readback path works under Mesa GLES. It is not proof of Mali driver behavior, the complete GS format matrix or correct game images. The same shader smoke is also included in the AArch64 `.muxapp` so that it can run on the physical H700. Its output is written to `logs/gles-shader-report.txt`.


## Latest exact full package · 21 November 2026

The current isolated branch HEAD \`f7e22324cabf38bcf370cff2632154897fbf03a9\` passed H700 run [#44722519260](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44722519260), all six jobs. The full runner is ELF64/AArch64 PIE with maximum required GLIBC \`GLIBC_2.30\` (Bullseye baseline \`2.31\`). The full muxapp inner SHA-256 is \`157b1cb574574cd68009fd2aa018bcad165ab561b5550522717e563ac1a8cf7f\`; uploaded artifact [#14623421505](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44722519260/artifacts/14623421505) is 5,572,650 bytes with outer digest \`935ceea794fdd51bac53197ea2236d9dd1df31cd2bbf158546857238725630a3\`.

The package verifier confirms one \`TwinsanityRintromped/\` root, launcher/language files, runtime and licence payload; it excludes the user's \`game.iso\` and \`disc-image.txt\`. The launcher host tests cover fallback to the root-level personal ISO, saved-path repair, parent-traversal rejection and symlink escape rejection.

This remains cross-build and package evidence only. The runner had no title ELF or game disc. Production shader execution on Mali, first NativeEE frame, game boot, controller, audio/video, disc streaming, saves and sustained gameplay remain unverified on hardware.


## Exact current full package · run 44891447801

The current H700 branch HEAD \`8fb339ab3b9210ec92fda2237553c8cb459d1424\` passed all six jobs in [run #44891447801](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44891447801). The full runner is ELF64/AArch64 PIE with maximum required GLIBC \`2.30\` (Bullseye baseline \`2.31\`). The inner muxapp SHA-256 is \`f1e740c3e32053a315d28124718f178e4e5601d9adfb8e325d5deb954d93be55\`; artifact [#14702635970](https://github.com/SilverCrow2323/Twinsanity-Rintromped-H700-Edition/actions/runs/44891447801/artifacts/14702635970) is 5,572,651 bytes with outer digest \`2be7846040b93e4fb157b1c9c4e748725b5c0e74b54aa4e677147b383caa518c\`.

The package verifier confirms one \`TwinsanityRintromped/\` root, launcher/language/runtime/licence assets and no user ISO. This is an exact CI package result, not proof of a NativeEE first frame or game boot on Mali. No controller, audio/video, disc streaming, saves or sustained gameplay is certified.