# H700 Porting Workspace

This directory contains the H700-specific development tools, hardware probes, packaging scripts and renderer validation harness.

> **CI release-candidate milestone reached:** the full AArch64 game runner now links with static LGPL FFmpeg and is packaged as a ZIP-based muOS `.muxapp`. A physical muOS Andromeda H700 has passed EGL 1.4, GLES 3.2 and SDL window presentation on Mali-G31; full-game boot and gameplay on that device are still unverified.

## Start here

**[Open the H700 Documentation Hub](../../docs/h700/README.md)** for the project overview, device profile, graphics port, build instructions, muOS installation, FAQ and roadmap.

| Area | Contents |
|---|---|
| device/ | EGL/GLES and SDL/GLES hardware probes, plus system inventory |
| renderer/ | Compile-only CMake gate for the real engine GL backend and SDL platform sources |
| scripts/ | Build, package and host-side checks for diagnostics and the full-game candidate |
| muos/ | muOS Application Runner entry point and language metadata |
| docs/ | API compatibility audit, test protocol and development notes |
| tools/ | Source-level GL API inventory tools |
| dist/ | CI-generated diagnostic binaries and installable archive (not committed) |

## Important distinction

The H700 artifacts now include both a diagnostic-only preflight `.muxapp` and a full-game candidate `.muxapp`. Both are ZIP archives renamed to `.muxapp`; neither includes the user's ISO. The full runner is CI-built, but its first boot and gameplay still need physical Mali-G31 validation. See the [installation guide](../../docs/h700/install.md) before installing either artifact.

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
