#!/bin/sh
# Host-only checks; these are not an H700 runtime test.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
# Guard the muOS archive root: the app directory must be the first path component.
grep -q 'APP="$STAGE/TwinsanityRintromped"' scripts/package-muxapp.sh
grep -q 'zip -qr "$TMP_ARCHIVE" TwinsanityRintromped' scripts/package-muxapp.sh
grep -q 'mv -f "$TMP_ARCHIVE" "$OUT_ABS"' scripts/package-muxapp.sh
if grep -q 'application/TwinsanityRintromped' scripts/package-muxapp.sh; then echo 'Legacy nested muxapp layout detected' >&2; exit 1; fi
if grep -R -n -F '\${' scripts device muos --exclude=test-kit.sh; then echo 'Found escaped shell expansion' >&2; exit 1; fi
for f in scripts/*.sh muos/TwinsanityRintromped/*.sh device/*.sh; do
  [ -f "$f" ] || continue
  case "$f" in
    scripts/build-ffmpeg-static.sh) bash -n "$f" ;;
    *) sh -n "$f" ;;
  esac
done
bash -n "$ROOT/../../tools/fetch_toolchain.sh"
bash -n "$ROOT/scripts/build-ffmpeg-static.sh"
sh -n "$ROOT/scripts/package-full-muxapp.sh"
python3 -c "from pathlib import Path; compile(Path('tools/gl_api_inventory.py').read_text(encoding='utf-8'), 'tools/gl_api_inventory.py', 'exec')"
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT HUP INT TERM
# X11 defines the global macro None as 0. The platform API must not use that
# token as an enum member because EGL includes Xlib before platform.h.
cat > "$TMP/platform-header-x11.cpp" <<'EOF'
#include <cstddef>
#include <cstdint>
#include <cstdio>
#define None 0
#include "engine/platform/platform.h"
static_assert(static_cast<int>(ps2r::platform::MapFlags::NoFlags) == 0);
static_assert(static_cast<int>(ps2r::platform::Prot::NoProtection) == 0);
int main() { return 0; }
EOF
c++ -std=c++17 -Wall -Wextra -Werror -I"$ROOT/../../engine" "$TMP/platform-header-x11.cpp" -o "$TMP/platform-header-x11"
cc -std=c11 -O2 -Wall -Wextra -Werror device/egl_gles_probe.c -ldl -o "$TMP/probe-host"
cc -std=c11 -O2 -Wall -Wextra -Werror device/sdl_gles_probe.c -ldl -o "$TMP/sdl-probe-host"
set +e
TW_H700_REPORT="$TMP/report.txt" "$TMP/probe-host" >"$TMP/stdout.txt" 2>&1
rc=$?
TW_H700_SDL_REPORT="$TMP/sdl-report.txt" "$TMP/sdl-probe-host" >"$TMP/sdl-stdout.txt" 2>&1
sdl_rc=$?
set -e
case "$rc" in 0|2|3|5) ;; *) cat "$TMP/stdout.txt" >&2; exit 1;; esac
case "$sdl_rc" in 0|2|3|5|6) ;; *) cat "$TMP/sdl-stdout.txt" >&2; exit 1;; esac
[ -s "$TMP/report.txt" ]
[ -s "$TMP/sdl-report.txt" ]
grep -q 'H700 EGL/GLES probe' "$TMP/report.txt"
grep -q 'H700 SDL/GLES window probe' "$TMP/sdl-report.txt"
if PROBE_BIN="$TMP/probe-host" SDL_PROBE_BIN="$TMP/sdl-probe-host" SHADER_PROBE_BIN="$TMP/probe-host" scripts/package-muxapp.sh "$TMP/should-not-exist.muxapp" >/dev/null 2>&1; then echo 'Accepted non-AArch64 binary' >&2; exit 1; fi
[ ! -e "$TMP/should-not-exist.muxapp" ]

# Exercise the actual full-game launcher without muOS. The packaged executable
# is runner/main.cpp; it rejects unknown flags, so the test double enforces the
# exact supported hand-off shape (--iso <image>) rather than merely echoing args.
mkdir -p "$TMP/launcher-app/My Discs"
printf '%s\\n' 'test disc bytes' > "$TMP/launcher-app/My Discs/Crash Twinsanity.iso"
cat > "$TMP/muos-func.sh" <<'EOF'
SETUP_APP() { :; }
EOF
cat > "$TMP/launcher-app/twinsanityevolved" <<'EOF'
#!/bin/sh
if [ "$#" -ne 2 ] || [ "$1" != "--iso" ]; then
  printf 'runner test stub: unsupported argument list:' >&2
  printf ' <%s>' "$@" >&2
  printf '\\n' >&2
  exit 64
fi
printf '%s\\n' "$@" > "$TW_H700_CAPTURE_ARGS"
printf '%s\\n' "$SDL_VIDEODRIVER" > "$TW_H700_CAPTURE_DRIVER"
if [ -n "${TW_H700_CAPTURE_PERF:-}" ]; then
  printf '%s\\n' "${TE_PROF:-}" "${TE_PROF_US:-}" "${TE_PROF_EVERY:-}" "${TE_GFX_SUMMARY_EVERY:-}" > "$TW_H700_CAPTURE_PERF"
fi
EOF
chmod 755 "$TMP/launcher-app/twinsanityevolved"
printf '%s\\n' 'My Discs/Crash Twinsanity.iso' > "$TMP/launcher-app/disc-image.txt"

run_launcher_expect_disc() {
  expected_disc="$1"
  rm -f "$TMP/launcher-args.txt"
  TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \\
  TW_H700_APP_DIR="$TMP/launcher-app" \\
  TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \\
  TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \\
    sh muos/TwinsanityRintromped/mux_launch.sh --muos-framework-argument
  [ "$(sed -n '1p' "$TMP/launcher-args.txt")" = "--iso" ]
  [ "$(sed -n '2p' "$TMP/launcher-args.txt")" = "$expected_disc" ]
  [ "$(wc -l < "$TMP/launcher-args.txt" | tr -d ' ')" = "2" ]
  [ "$(cat "$TMP/launcher-driver.txt")" = "mali" ]
}

# Default, flat and sectioned launcher.show values must never leak the
# unsupported --launcher flag into the standalone runner's CLI.
run_launcher_expect_disc "$TMP/launcher-app/My Discs/Crash Twinsanity.iso"
mkdir -p "$TMP/launcher-app/userdata"
printf '%s\\n' '[launcher]' 'show = off' > "$TMP/launcher-app/userdata/ps2r.ini"
run_launcher_expect_disc "$TMP/launcher-app/My Discs/Crash Twinsanity.iso"
printf '%s\\n' 'launcher.show = on' > "$TMP/launcher-app/userdata/ps2r.ini"
run_launcher_expect_disc "$TMP/launcher-app/My Discs/Crash Twinsanity.iso"

# The one-shot performance marker enables bounded diagnostics, removes itself
# before the runner starts, and is inert on ordinary launches.
mkdir -p "$TMP/launcher-app/logs"
: > "$TMP/launcher-app/logs/performance-diagnostics.once"
rm -f "$TMP/launcher-perf.txt"
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \\
TW_H700_APP_DIR="$TMP/launcher-app" \\
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \\
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \\
TW_H700_CAPTURE_PERF="$TMP/launcher-perf.txt" \\
  sh muos/TwinsanityRintromped/mux_launch.sh
[ "$(sed -n '1p' "$TMP/launcher-perf.txt")" = "1" ]
[ "$(sed -n '2p' "$TMP/launcher-perf.txt")" = "2000" ]
[ "$(sed -n '3p' "$TMP/launcher-perf.txt")" = "120" ]
[ "$(sed -n '4p' "$TMP/launcher-perf.txt")" = "120" ]
[ ! -e "$TMP/launcher-app/logs/performance-diagnostics.once" ]

# A broken saved selection must fall back to game.iso and repair the selection.
rm -f "$TMP/launcher-app/My Discs/Crash Twinsanity.iso" "$TMP/launcher-args.txt"
printf '%s\\n' 'missing.iso' > "$TMP/launcher-app/disc-image.txt"
printf '%s\\n' 'fallback disc bytes' > "$TMP/launcher-app/game.iso"
run_launcher_expect_disc "$TMP/launcher-app/game.iso"
[ "$(cat "$TMP/launcher-app/disc-image.txt")" = "game.iso" ]

# A saved relative path must not escape the application root. The safe
# root-level game.iso is selected instead, and the saved selection is repaired.
printf '%s\\n' 'outside disc bytes' > "$TMP/outside.iso"
printf '%s\\n' '../outside.iso' > "$TMP/launcher-app/disc-image.txt"
printf '%s\\n' 'safe in-app disc bytes' > "$TMP/launcher-app/game.iso"
run_launcher_expect_disc "$TMP/launcher-app/game.iso"
[ "$(cat "$TMP/launcher-app/disc-image.txt")" = "game.iso" ]

# A symlinked game.iso must not make the launcher read a disc outside the app.
rm -f "$TMP/launcher-app/game.iso" "$TMP/launcher-app/disc-image.txt" "$TMP/launcher-args.txt"
ln -s "$TMP/outside.iso" "$TMP/launcher-app/game.iso"
set +e
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \\
TW_H700_APP_DIR="$TMP/launcher-app" \\
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \\
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \\
  sh muos/TwinsanityRintromped/mux_launch.sh >/dev/null 2>&1
link_rc=$?
set -e
[ "$link_rc" -eq 2 ]
[ ! -e "$TMP/launcher-args.txt" ]

echo 'Host checks passed (device and AArch64 runtime tests pending).'
