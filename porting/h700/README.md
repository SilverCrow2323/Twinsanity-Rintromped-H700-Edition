# H700 Porting Workspace

This directory contains the H700-specific development tools, hardware probes, packaging scripts and renderer validation harness.

> **Hardware milestone reached:** a physical muOS Andromeda H700 device passed EGL 1.4, GLES 3.2 and SDL window presentation on the Mali-G31. The NativeEE game renderer is still being adapted; no playable H700 build is available yet.

## Start here

**[Open the H700 Documentation Hub](../../docs/h700/README.md)** for the project overview, device profile, graphics port, build instructions, muOS installation, FAQ and roadmap.

| Area | Contents |
|---|---|
| device/ | EGL/GLES and SDL/GLES hardware probes, plus system inventory |
| renderer/ | Compile-only CMake gate for the real engine GL backend and SDL platform sources |
| scripts/ | Build, package and host-side checks for the diagnostic app |
| muos/ | muOS Application Runner entry point and language metadata |
| docs/ | API compatibility audit, test protocol and development notes |
| tools/ | Source-level GL API inventory tools |
| dist/ | CI-generated diagnostic binaries and installable archive (not committed) |

## Important distinction

The preflight .muxapp is a diagnostic application. It does not start the NativeEE engine, parse game.iso, or run game code. See the [installation guide](../../docs/h700/install.md) before using it.

## Core commands

Run the host-side checks:

~~~bash
cd porting/h700
./scripts/test-kit.sh
~~~

Compile the renderer against GLES 3.2 headers:

~~~bash
cmake -S porting/h700/renderer -B build/h700-gles -G Ninja \
  -DCMAKE_SYSTEM_NAME=Linux \
  -DCMAKE_SYSTEM_PROCESSOR=aarch64 \
  -DCMAKE_CXX_COMPILER=aarch64-linux-gnu-g++

cmake --build build/h700-gles --target h700_gles_compile_check --parallel 2
~~~

See the [build guide](../../docs/h700/building.md) for dependencies and validation boundaries.
