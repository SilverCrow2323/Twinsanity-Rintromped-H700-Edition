#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/../../.." && pwd)
OUT=${1:-"$ROOT/porting/h700/dist/Twinsanity-Rintromped-H700-Edition.muxapp"}
GAME_BIN=${GAME_BIN:-"$ROOT/build/h700-full-aarch64/twinsanityevolved"}
PROBE_BIN=${PROBE_BIN:-"$ROOT/porting/h700/dist/tw-rintromped-h700-probe"}
SDL_BIN=${SDL_PROBE_BIN:-"$ROOT/porting/h700/dist/tw-rintromped-h700-sdl-probe"}
SHADER_BIN=${SHADER_PROBE_BIN:-"$ROOT/porting/h700/dist/tw-rintromped-h700-gles-shader-smoke"}
LAUNCHER="$ROOT/porting/h700/muos/TwinsanityRintromped/mux_launch.sh"
LANG_FILE="$ROOT/porting/h700/muos/TwinsanityRintromped/mux_lang.ini"
DEVICE_SCRIPT="$ROOT/porting/h700/device/collect-system-info.sh"
FFMPEG_LICENSE_DIR=${FFMPEG_LICENSE_DIR:-"$ROOT/build/h700-full-aarch64/third_party/ffmpeg/share/licenses"}

for item in "$GAME_BIN" "$PROBE_BIN" "$SDL_BIN" "$SHADER_BIN"; do
  [ -f "$item" ] || { echo "Missing binary required by full muxapp: $item" >&2; exit 1; }
done
for item in "$LAUNCHER" "$LANG_FILE" "$DEVICE_SCRIPT"; do
  [ -f "$item" ] || { echo "Missing application file: $item" >&2; exit 1; }
done
for item in FFmpeg-COPYING.LGPLv2.1.txt FFmpeg-LICENSE.md FFmpeg-BUILD-CONFIGURATION.txt; do
  [ -s "$FFMPEG_LICENSE_DIR/$item" ] || { echo "Missing static FFmpeg licence/build proof: $FFMPEG_LICENSE_DIR/$item" >&2; exit 1; }
done
command -v readelf >/dev/null 2>&1 || { echo "Missing readelf" >&2; exit 2; }
command -v zip >/dev/null 2>&1 || { echo "Missing zip" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python3 for archive verification" >&2; exit 2; }

for binary in "$GAME_BIN" "$PROBE_BIN" "$SDL_BIN" "$SHADER_BIN"; do
  readelf -h "$binary" | grep -Eq 'Class:.*ELF64' || { echo "Refusing non-ELF64 binary: $binary" >&2; exit 1; }
  readelf -h "$binary" | grep -Eq 'Machine:.*AArch64' || { echo "Refusing non-AArch64 binary: $binary" >&2; exit 1; }
done
max=$(readelf --version-info "$GAME_BIN" | grep -o 'GLIBC_[0-9.]*' | sort -Vu | tail -n 1 || true)
echo "twinsanityevolved maximum required GLIBC symbol: ${max:-none}"
if [ -n "$max" ] && [ "$(printf '%s\n' "$max" GLIBC_2.31 | sort -V | tail -n 1)" != "GLIBC_2.31" ]; then
  echo "Runner requires $max; refusing a muOS-incompatible binary (baseline GLIBC 2.31)." >&2
  exit 1
fi
if readelf -d "$GAME_BIN" 2>/dev/null | grep -Eq 'libav(codec|util|swscale).*\.so'; then
  echo "Runner still depends on dynamic FFmpeg; H700 release must carry the static LGPL archives." >&2
  exit 1
fi
if readelf -d "$GAME_BIN" 2>/dev/null | grep -Eq 'libGL\.so|libOpenGL\.so'; then
  echo "Runner links desktop OpenGL instead of the H700 GLES backend." >&2
  exit 1
fi

STAGE=$(mktemp -d)
mkdir -p "$(dirname "$OUT")"
OUT_DIR=$(CDPATH= cd -- "$(dirname -- "$OUT")" && pwd)
OUT_ABS="$OUT_DIR/$(basename -- "$OUT")"
TMP_ARCHIVE_DIR=$(mktemp -d "$OUT_DIR/.muxapp-build.XXXXXX")
TMP_ARCHIVE="$TMP_ARCHIVE_DIR/$(basename -- "$OUT")"
trap 'rm -rf "$STAGE" "$TMP_ARCHIVE_DIR"' EXIT HUP INT TERM
APP="$STAGE/TwinsanityRintromped"
mkdir -p "$APP/device" "$APP/logs" "$APP/licenses"
# The first installed launch automatically collects one low-overhead performance report.
: > "$APP/logs/performance-diagnostics.once"
cp "$GAME_BIN" "$APP/twinsanityevolved"
cp "$PROBE_BIN" "$APP/tw-rintromped-h700-probe"
cp "$SDL_BIN" "$APP/tw-rintromped-h700-sdl-probe"
cp "$SHADER_BIN" "$APP/tw-rintromped-h700-gles-shader-smoke"
cp "$LAUNCHER" "$APP/mux_launch.sh"
cp "$LANG_FILE" "$APP/mux_lang.ini"
cp "$DEVICE_SCRIPT" "$APP/device/collect-system-info.sh"
cp "$FFMPEG_LICENSE_DIR/FFmpeg-COPYING.LGPLv2.1.txt" "$APP/licenses/"
cp "$FFMPEG_LICENSE_DIR/FFmpeg-LICENSE.md" "$APP/licenses/"
cp "$FFMPEG_LICENSE_DIR/FFmpeg-BUILD-CONFIGURATION.txt" "$APP/licenses/"
cp "$ROOT/LICENSE" "$APP/licenses/TwinsanityEvolved-LICENSE.txt"
cp "$ROOT/RELEASE-NOTES.txt" "$APP/RELEASE-NOTES.txt"
cat > "$APP/README.txt" <<'EOF'
Twinsanity Rintromped - H700 Edition

This archive contains the AArch64 game runner and hardware diagnostics.
It does NOT contain game data or a disc image.

Put your own game.iso in this application folder:
  MUOS/application/TwinsanityRintromped/game.iso

On launch, the muOS launcher selects game.iso only when no valid
disc-image.txt selection exists. The ISO is never modified.

Diagnostic reports are written to:
  MUOS/application/TwinsanityRintromped/logs/

The installed runner uses the device's SDL2, EGL and GLES runtime.

H700 performance notes:
- GLES enables adjacent blended-draw joining and shadow-volume draw grouping by default.
- The batches preserve draw/state order and reduce repeated submissions to the Mali driver.
- GLES uniform changes are batched for the selected draw program to reduce per-uniform driver state queries.
- Set TE_GFX_UNIFORM_SYNC=0 before launching the runner to restore the conservative immediate uploader for A/B testing.
- The first launch after installing this package automatically collects one low-overhead report. The marker is consumed automatically.
- To collect another report later, create an empty file at:
    logs/performance-diagnostics.once
  Then launch the game. The resulting logs/game-launch.log includes CPU samples and frame/build/render timings.

FFmpeg's MPEG-1/2 decoder, MPEG video parser and swscale are linked
statically; see licenses/ for the LGPL v2.1+ texts and build proof.
EOF
chmod 755 "$APP/mux_launch.sh" "$APP/device/collect-system-info.sh" \
  "$APP/twinsanityevolved" "$APP/tw-rintromped-h700-probe" \
  "$APP/tw-rintromped-h700-sdl-probe" "$APP/tw-rintromped-h700-gles-shader-smoke"
(cd "$STAGE" && zip -X -qr "$TMP_ARCHIVE" TwinsanityRintromped)
python3 - "$TMP_ARCHIVE" <<'PY'
import sys
import zipfile

path = sys.argv[1]
if not zipfile.is_zipfile(path):
    raise SystemExit("Full muxapp is not a ZIP archive renamed to .muxapp")
with open(path, "rb") as stream:
    if stream.read(4) != b"PK\x03\x04":
        raise SystemExit("Full muxapp has no ZIP local-file signature")
with zipfile.ZipFile(path) as archive:
    corrupt = archive.testzip()
    if corrupt:
        raise SystemExit(f"Corrupt ZIP member: {corrupt}")
    names = set(archive.namelist())
    roots = {name.split("/", 1)[0] for name in names if name}
    if roots != {"TwinsanityRintromped"}:
        raise SystemExit(f"Unexpected root entries: {sorted(roots)}")
    required = {
        "TwinsanityRintromped/twinsanityevolved",
        "TwinsanityRintromped/mux_launch.sh",
        "TwinsanityRintromped/mux_lang.ini",
        "TwinsanityRintromped/tw-rintromped-h700-probe",
        "TwinsanityRintromped/tw-rintromped-h700-sdl-probe",
        "TwinsanityRintromped/tw-rintromped-h700-gles-shader-smoke",
        "TwinsanityRintromped/device/collect-system-info.sh",
        "TwinsanityRintromped/README.txt",
        "TwinsanityRintromped/logs/performance-diagnostics.once",
        "TwinsanityRintromped/licenses/FFmpeg-COPYING.LGPLv2.1.txt",
        "TwinsanityRintromped/licenses/FFmpeg-BUILD-CONFIGURATION.txt",
    }
    missing = sorted(required - names)
    if missing:
        raise SystemExit("Full muxapp is missing: " + ", ".join(missing))
    if any(name.lower().endswith(("/game.iso", "/disc-image.txt")) for name in names):
        raise SystemExit("Refusing to package a user disc image or disc selection")
print("Full muxapp ZIP integrity, root layout, diagnostics and license payload verified.")
PY
mv -f "$TMP_ARCHIVE" "$OUT_ABS"
sha256sum "$OUT_ABS"
echo "Created $OUT_ABS"
