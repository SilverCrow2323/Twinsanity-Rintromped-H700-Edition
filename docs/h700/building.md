# Build guide

## Build profiles

The engine keeps desktop OpenGL as its default. H700 builds must opt in explicitly:

~~~text
-DPS2R_GLES=ON
~~~

The option is Linux-only. It selects GLES headers, resolves GLESv2 and asks SDL for an OpenGL ES 3.2 context. It must not be enabled in Windows, macOS or Vita builds.

## Compile-only renderer gate

The repository includes a small standalone CMake project at porting/h700/renderer. It compiles the actual GL backend and SDL window/context source files against GLES 3.2 and SDL2 headers. It does not link a game executable or test the runtime.

Host prerequisites on Ubuntu:

~~~bash
sudo apt-get update
sudo apt-get install -y \
  g++-aarch64-linux-gnu cmake ninja-build \
  libgles2-mesa-dev libsdl2-dev
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

The complete TwinsanityEvolved build also uses its pinned WASI SDK and WABT toolchain for the decompiled game module. Follow the upstream toolchain setup first, then configure the root project with the target cross-compilers and PS2R_GLES enabled.

~~~bash
./tools/fetch_toolchain.sh

cmake -S . -B build-h700 -G Ninja \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_C_COMPILER=aarch64-linux-gnu-gcc \
  -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++ \
  -DPS2R_GLES=ON
~~~

The full project may require further target-specific dependencies and configuration. The compile-only gate is intentionally independent so renderer API issues can be found before the whole game pipeline is ready.

## CI workflow

The H700 workflow now contains separate validation lanes:

| Job | Purpose |
|---|---|
| host-checks | Shell, probe, packaging and host safety checks |
| gles-renderer-compile | Cross-compiles renderer and SDL objects against GLES headers |
| aarch64-package | Builds and packages the hardware diagnostic utility |

The diagnostic package is not the game binary. The build artifact must never be described as playable until the renderer and game runtime milestones have passed.

## Debugging a compile failure

Record the first failing translation unit and the exact undefined type, constant or function. Classify it as one of:

- Desktop-only API requiring an adapter.
- GLES API available but missing from the current include / library setup.
- Engine dependency or generated header missing from the isolated compile project.
- Genuine source portability issue unrelated to graphics.

Do not silence errors with global macros or by substituting a desktop GL header into the GLES target.
