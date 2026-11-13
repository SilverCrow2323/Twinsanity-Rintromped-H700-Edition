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

# Exercise the actual full-game launcher without muOS. The runner's CLI
# requires --iso <path>; the prelaunch screen is force-enabled with --launcher
# because --iso otherwise marks this as a direct/harness-style invocation.
mkdir -p "$TMP/launcher-app/My Discs"
printf '%s\n' 'test disc bytes' > "$TMP/launcher-app/My Discs/Crash Twinsanity.iso"
cat > "$TMP/muos-func.sh" <<'EOF'
SETUP_APP() { :; }
EOF
cat > "$TMP/launcher-app/twinsanityevolved" <<'EOF'
#!/bin/sh
printf '%s\n' "$@" > "$TW_H700_CAPTURE_ARGS"
printf '%s\n' "$SDL_VIDEODRIVER" > "$TW_H700_CAPTURE_DRIVER"
if [ -n "${TW_H700_CAPTURE_PERF:-}" ]; then
  printf '%s\n' "${TE_PROF:-}" "${TE_PROF_US:-}" "${TE_PROF_EVERY:-}" "${TE_GFX_SUMMARY_EVERY:-}" > "$TW_H700_CAPTURE_PERF"
fi
EOF
chmod 755 "$TMP/launcher-app/twinsanityevolved"
printf '%s\n' 'My Discs/Crash Twinsanity.iso' > "$TMP/launcher-app/disc-image.txt"
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \
TW_H700_APP_DIR="$TMP/launcher-app" \
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \
  sh muos/TwinsanityRintromped/mux_launch.sh --muos-framework-argument
[ "$(sed -n '1p' "$TMP/launcher-args.txt")" = "--iso" ]
[ "$(sed -n '2p' "$TMP/launcher-args.txt")" = "$TMP/launcher-app/My Discs/Crash Twinsanity.iso" ]
[ "$(sed -n '3p' "$TMP/launcher-args.txt")" = "--launcher" ]
[ "$(wc -l < "$TMP/launcher-args.txt" | tr -d ' ')" = "3" ]
[ "$(cat "$TMP/launcher-driver.txt")" = "mali" ]

# The one-shot performance marker enables bounded diagnostics, removes itself
# before the runner starts, and is inert on ordinary launches.
mkdir -p "$TMP/launcher-app/logs"
: > "$TMP/launcher-app/logs/performance-diagnostics.once"
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \
TW_H700_APP_DIR="$TMP/launcher-app" \
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \
TW_H700_CAPTURE_PERF="$TMP/launcher-perf.txt" \
  sh muos/TwinsanityRintromped/mux_launch.sh
[ "$(sed -n '1p' "$TMP/launcher-perf.txt")" = "1" ]
[ "$(sed -n '2p' "$TMP/launcher-perf.txt")" = "2000" ]
[ "$(sed -n '3p' "$TMP/launcher-perf.txt")" = "120" ]
[ "$(sed -n '4p' "$TMP/launcher-perf.txt")" = "120" ]
[ ! -e "$TMP/launcher-app/logs/performance-diagnostics.once" ]

# A broken saved selection must fall back to game.iso and repair the selection.
rm -f "$TMP/launcher-app/My Discs/Crash Twinsanity.iso" "$TMP/launcher-args.txt"
printf '%s\n' 'missing.iso' > "$TMP/launcher-app/disc-image.txt"
printf '%s\n' 'fallback disc bytes' > "$TMP/launcher-app/game.iso"
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \
TW_H700_APP_DIR="$TMP/launcher-app" \
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \
  sh muos/TwinsanityRintromped/mux_launch.sh
[ "$(sed -n '1p' "$TMP/launcher-args.txt")" = "--iso" ]
[ "$(sed -n '2p' "$TMP/launcher-args.txt")" = "$TMP/launcher-app/game.iso" ]
[ "$(sed -n '3p' "$TMP/launcher-args.txt")" = "--launcher" ]
[ "$(cat "$TMP/launcher-app/disc-image.txt")" = "game.iso" ]

# No valid image must fail before invoking the game runner.
rm -f "$TMP/launcher-app/game.iso" "$TMP/launcher-args.txt"
set +e
TW_H700_MUOS_FUNC_SH="$TMP/muos-func.sh" \
TW_H700_APP_DIR="$TMP/launcher-app" \
TW_H700_CAPTURE_ARGS="$TMP/launcher-args.txt" \
TW_H700_CAPTURE_DRIVER="$TMP/launcher-driver.txt" \
  sh muos/TwinsanityRintromped/mux_launch.sh >/dev/null 2>&1
launch_rc=$?
set -e
[ "$launch_rc" -eq 2 ]
[ ! -e "$TMP/launcher-args.txt" ]

# Rebuild over an existing package and prove that obsolete ZIP entries are removed.
python3 - "$TMP/fake-aarch64" <<'PY'
import struct
import sys
ident = b"\x7fELF" + bytes([2, 1, 1, 0, 0]) + bytes(7)
header = struct.pack("<16sHHIQQQIHHHHHH", ident, 2, 183, 1, 0, 0, 0, 0, 64, 56, 0, 64, 0, 0)
with open(sys.argv[1], "wb") as stream:
    stream.write(header)
PY
chmod 755 "$TMP/fake-aarch64"
PROBE_BIN="$TMP/fake-aarch64" SDL_PROBE_BIN="$TMP/fake-aarch64" SHADER_PROBE_BIN="$TMP/fake-aarch64" \
  scripts/package-muxapp.sh "$TMP/rebuild.muxapp" >/dev/null
python3 - "$TMP/rebuild.muxapp" <<'PY'
import sys
import zipfile
with zipfile.ZipFile(sys.argv[1], "a") as archive:
    archive.writestr("obsolete/old-layout-marker.txt", "must disappear on rebuild")
PY
PROBE_BIN="$TMP/fake-aarch64" SDL_PROBE_BIN="$TMP/fake-aarch64" SHADER_PROBE_BIN="$TMP/fake-aarch64" \
  scripts/package-muxapp.sh "$TMP/rebuild.muxapp" >/dev/null
python3 - "$TMP/rebuild.muxapp" <<'PY'
import sys
import zipfile
if not zipfile.is_zipfile(sys.argv[1]):
    raise SystemExit("Muxapp is not a ZIP archive renamed to .muxapp")
with open(sys.argv[1], "rb") as stream:
    if stream.read(4) != b"PK\x03\x04":
        raise SystemExit("Muxapp does not start with the ZIP local-file signature")
with zipfile.ZipFile(sys.argv[1]) as archive:
    if archive.testzip() is not None:
        raise SystemExit("Muxapp ZIP integrity check failed")
    names = archive.namelist()
    if "obsolete/old-layout-marker.txt" in names:
        raise SystemExit("Stale ZIP entry survived package rebuild")
    roots = {name.split("/", 1)[0] for name in names if name}
    if roots != {"TwinsanityRintromped"}:
        raise SystemExit(f"Unexpected muxapp root entries: {sorted(roots)}")
    required = {
        "TwinsanityRintromped/mux_launch.sh",
        "TwinsanityRintromped/mux_lang.ini",
    }
    missing = sorted(required - set(names))
    if missing:
        raise SystemExit("Missing muxapp entries after rebuild: " + ", ".join(missing))
print("Muxapp rebuild removes stale entries and preserves the required root layout.")
PY
# Protect the SDL event hand-off: ps2e_draw_pump runs before the pad sampler
# and must not swallow controller events (especially MENU + START).
DRAW_SOURCE="$ROOT/../../engine/engine/platform/ps2e/ps2e_draw.cpp"
LAUNCHER_SOURCE="$ROOT/../../engine/app/host/launcher.cpp"
grep -q 'SDL_PushEvent(&forwarded)' "$DRAW_SOURCE"
grep -q 'SDL_CONTROLLERBUTTONDOWN' "$DRAW_SOURCE"
grep -q 'SDL_WINDOWEVENT_FOCUS_LOST' "$DRAW_SOURCE"
grep -q 'SDL_GameControllerAddMapping(mapping.c_str())' "$LAUNCHER_SOURCE"
grep -q 'settings_.reset()' "$LAUNCHER_SOURCE"

# Exercise the complete game muxapp packager with synthetic AArch64 ELF files.
# GitHub Actions artifact downloads may restore files as 0644; the packager must
# accept regular ELF files and set executable mode on the staged application copy.
chmod 644 "$TMP/fake-aarch64"
mkdir -p "$TMP/fake-ffmpeg/share/licenses"
printf '%s\n' 'FFmpeg LGPL v2.1 text fixture' > "$TMP/fake-ffmpeg/share/licenses/FFmpeg-COPYING.LGPLv2.1.txt"
printf '%s\n' 'FFmpeg licence fixture' > "$TMP/fake-ffmpeg/share/licenses/FFmpeg-LICENSE.md"
printf '%s\n' 'configuration fixture: --enable-decoder=mpeg2video' > "$TMP/fake-ffmpeg/share/licenses/FFmpeg-BUILD-CONFIGURATION.txt"
GAME_BIN="$TMP/fake-aarch64" PROBE_BIN="$TMP/fake-aarch64" \
SDL_PROBE_BIN="$TMP/fake-aarch64" SHADER_PROBE_BIN="$TMP/fake-aarch64" \
FFMPEG_LICENSE_DIR="$TMP/fake-ffmpeg/share/licenses" \
  scripts/package-full-muxapp.sh "$TMP/full-muxapp.muxapp" >/dev/null
python3 - "$TMP/full-muxapp.muxapp" <<'PY'
import sys
import zipfile
p = sys.argv[1]
if not zipfile.is_zipfile(p):
    raise SystemExit("Full muxapp is not a ZIP archive renamed to .muxapp")
with open(p, "rb") as stream:
    if stream.read(4) != b"PK\x03\x04":
        raise SystemExit("Full muxapp ZIP signature is invalid")
with zipfile.ZipFile(p) as archive:
    if archive.testzip() is not None:
        raise SystemExit("Full muxapp contains a corrupt ZIP member")
    names = set(archive.namelist())
    roots = {name.split("/", 1)[0] for name in names if name}
    if roots != {"TwinsanityRintromped"}:
        raise SystemExit(f"Unexpected full muxapp root: {sorted(roots)}")
    for name in ("TwinsanityRintromped/twinsanityevolved",
                 "TwinsanityRintromped/mux_launch.sh",
                 "TwinsanityRintromped/tw-rintromped-h700-gles-shader-smoke"):
        if name not in names:
            raise SystemExit("Full muxapp missing " + name)
    if any(name.lower().endswith(("/game.iso", "/disc-image.txt")) for name in names):
        raise SystemExit("Full muxapp must not contain user disc data or selection")
print("Full muxapp ZIP package test passed.")
PY

echo 'Host checks passed (device and AArch64 runtime tests pending).'
