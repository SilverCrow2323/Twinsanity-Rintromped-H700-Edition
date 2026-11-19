# H700 Porting Workspace

This directory contains the H700-specific development tools, hardware probes, packaging scripts and renderer validation harness.

> **0.2.5-dev physical checkpoint:** the PAL image reaches the beach hub on the H700/Mali-G31, but the kernel later terminates `te-game` through the OOM killer. The cause is now confirmed as memory pressure; the exact source of the large file-backed RSS is still being isolated. This branch adds first-draw texture decoding, H700-specific cache budgets and process RSS telemetry. CI and a fresh device run must pass before this mitigation can be called validated.

## Start here

**[Open the H700 Documentation Hub](../../docs/h700/README.md)** for the project overview, device profile, graphics port, build instructions, muOS installation, FAQ and roadmap.

| Area | Contents |
|---|---|
| device/ | EGL/GLES and SDL/GLES hardware probes, plus system inventory |
| renderer/ | Compile-only CMake gate for the real engine GL backend and SDL platform sources |
| scripts/ | Build, package and host-side checks for diagnostics and the NativeEE runner candidate |
| muos/ | muOS Application Runner entry point and language metadata |
| docs/ | API compatibility audit, test protocol and development notes |
| tools/ | Source-level GL API inventory tools |
| dist/ | CI-generated diagnostic binaries and installable archive (not committed) |

## Important distinction

The H700 artifacts include a diagnostic-only preflight `.muxapp` and a NativeEE runner-candidate `.muxapp`. Both are ZIP archives renamed to `.muxapp`; neither includes the user's ISO. The physical PAL boot reached the beach hub, but sustained gameplay is blocked by the confirmed OOM condition. The memory-limited candidate is not yet a validated fix. See the [installation guide](../../docs/h700/install.md) before installing an artifact.

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
