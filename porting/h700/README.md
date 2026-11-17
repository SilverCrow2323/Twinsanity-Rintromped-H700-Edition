# H700 Porting Workspace

This directory contains the H700-specific development tools, hardware probes, packaging scripts and renderer validation harness.

> **CI NativeEE runner/package milestone:** the AArch64 runner links with static LGPL FFmpeg and is packaged as a ZIP-based muOS `.muxapp`. H700 run #310 is green, but CI had no title ELF/disc input: title-specific recompilation, game composition and title-dependent EE/CDVD tests were skipped. A 13 November physical H700/Mali-G31 bring-up of an earlier runner reached NativeEE startup, loaded the user's PAL `SLES-52568` retail ELF and initialised gamepad/audio plus GLES; it then failed on the first vertex shader. The shader normaliser fix now passes Mesa CI, but no post-fix Mali retest, first NativeEE frame or gameplay is documented. This is not a playable-game claim.

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

The H700 artifacts include a diagnostic-only preflight `.muxapp` and a NativeEE runner-candidate `.muxapp`. Both are ZIP archives renamed to `.muxapp`; neither includes the user's ISO. The current CI runner was linked without a title ELF/disc input, so the game-specific recompile and composition gates were skipped. Its first frame and gameplay remain unverified; the earlier 13 November physical bring-up failed at the first vertex shader before the normaliser fix was added. See the [installation guide](../../docs/h700/install.md) before installing either artifact.

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
