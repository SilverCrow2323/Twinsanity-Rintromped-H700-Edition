#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/dist/Twinsanity-Rintromped-H700-Edition.muxapp"}
BIN=${PROBE_BIN:-"$ROOT/dist/tw-rintromped-h700-probe"}
SDL_BIN=${SDL_PROBE_BIN:-"$ROOT/dist/tw-rintromped-h700-sdl-probe"}
SHADER_BIN=${SHADER_PROBE_BIN:-"$ROOT/dist/tw-rintromped-h700-gles-shader-smoke"}
[ -x "$BIN" ] || { echo "Missing AArch64 EGL/GLES diagnostic binary; run scripts/build-probe.sh first." >&2; exit 1; }
[ -x "$SDL_BIN" ] || { echo "Missing AArch64 SDL/GLES diagnostic binary; run scripts/build-probe.sh first." >&2; exit 1; }
[ -x "$SHADER_BIN" ] || { echo "Missing AArch64 NativeEE GLES shader smoke binary; build h700_gles_shader_smoke first." >&2; exit 1; }
command -v readelf >/dev/null 2>&1 || { echo "Missing readelf" >&2; exit 2; }
command -v zip >/dev/null 2>&1 || { echo "Missing zip" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python3 for archive verification" >&2; exit 2; }
for binary in "$BIN" "$SDL_BIN" "$SHADER_BIN"; do
  readelf -h "$binary" | grep -Eq 'Machine:.*AArch64' || { echo "Refusing non-AArch64 binary: $binary" >&2; exit 1; }
done
STAGE=$(mktemp -d)
mkdir -p "$(dirname "$OUT")"
OUT_DIR=$(CDPATH= cd -- "$(dirname -- "$OUT")" && pwd)
OUT_ABS="$OUT_DIR/$(basename -- "$OUT")"
TMP_ARCHIVE_DIR=$(mktemp -d "$OUT_DIR/.muxapp-build.XXXXXX")
TMP_ARCHIVE="$TMP_ARCHIVE_DIR/$(basename -- "$OUT")"
trap 'rm -rf "$STAGE" "$TMP_ARCHIVE_DIR"' EXIT HUP INT TERM
APP="$STAGE/TwinsanityRintromped"
mkdir -p "$APP/device" "$APP/logs"
cp "$BIN" "$APP/tw-rintromped-h700-probe"
cp "$SDL_BIN" "$APP/tw-rintromped-h700-sdl-probe"
cp "$SHADER_BIN" "$APP/tw-rintromped-h700-gles-shader-smoke"
cp "$ROOT/muos/TwinsanityRintromped/mux_launch.sh" "$APP/mux_launch.sh"
cp "$ROOT/muos/TwinsanityRintromped/mux_lang.ini" "$APP/mux_lang.ini"
cp "$ROOT/device/collect-system-info.sh" "$APP/device/collect-system-info.sh"
chmod 755 "$APP/mux_launch.sh" "$APP/device/collect-system-info.sh" \
  "$APP/tw-rintromped-h700-probe" "$APP/tw-rintromped-h700-sdl-probe" \
  "$APP/tw-rintromped-h700-gles-shader-smoke"
(cd "$STAGE" && zip -qr "$TMP_ARCHIVE" TwinsanityRintromped)
python3 - "$TMP_ARCHIVE" <<'PY'
import sys
import zipfile
archive_path = sys.argv[1]
with zipfile.ZipFile(archive_path) as archive:
    corrupt = archive.testzip()
    if corrupt:
        raise SystemExit(f"Corrupt archive entry: {corrupt}")
    names = set(archive.namelist())
    required = {
        "TwinsanityRintromped/mux_launch.sh",
        "TwinsanityRintromped/mux_lang.ini",
        "TwinsanityRintromped/tw-rintromped-h700-probe",
        "TwinsanityRintromped/tw-rintromped-h700-sdl-probe",
        "TwinsanityRintromped/tw-rintromped-h700-gles-shader-smoke",
        "TwinsanityRintromped/device/collect-system-info.sh",
    }
    if any(name.startswith("application/") for name in names):
        raise SystemExit("Invalid muxapp layout: do not nest app under application/")
    missing = sorted(required - names)
    if missing:
        raise SystemExit("Missing muxapp entries: " + ", ".join(missing))
print("Muxapp ZIP integrity and layout verified.")
PY
# Replace the previous package only after the fresh archive has passed validation.
# Writing to a temporary archive prevents stale ZIP entries surviving a rebuild.
mv -f "$TMP_ARCHIVE" "$OUT_ABS"
sha256sum "$OUT_ABS"
echo "Created $OUT_ABS"
