#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${1:-"$ROOT/dist/Twinsanity-Rintromped-H700-Edition.muxapp"}
BIN=${PROBE_BIN:-"$ROOT/dist/tw-rintromped-h700-probe"}
[ -x "$BIN" ] || { echo "Missing AArch64 diagnostic binary; run scripts/build-probe.sh first." >&2; exit 1; }
command -v readelf >/dev/null 2>&1 || { echo "Missing readelf" >&2; exit 2; }
command -v zip >/dev/null 2>&1 || { echo "Missing zip" >&2; exit 2; }
command -v python3 >/dev/null 2>&1 || { echo "Missing python3 for archive verification" >&2; exit 2; }
readelf -h "$BIN" | grep -Eq 'Machine:.*AArch64' || { echo "Refusing non-AArch64 binary" >&2; exit 1; }
STAGE=$(mktemp -d); trap 'rm -rf "$STAGE"' EXIT HUP INT TERM
APP="$STAGE/application/TwinsanityRintromped"
mkdir -p "$APP/device" "$APP/logs"
cp "$BIN" "$APP/tw-rintromped-h700-probe"
cp "$ROOT/muos/TwinsanityRintromped/mux_launch.sh" "$APP/mux_launch.sh"
cp "$ROOT/muos/TwinsanityRintromped/mux_lang.ini" "$APP/mux_lang.ini"
cp "$ROOT/device/collect-system-info.sh" "$APP/device/collect-system-info.sh"
chmod 755 "$APP/mux_launch.sh" "$APP/device/collect-system-info.sh" "$APP/tw-rintromped-h700-probe"
mkdir -p "$(dirname "$OUT")"
OUT_ABS=$(CDPATH= cd -- "$(dirname -- "$OUT")" && pwd)/$(basename -- "$OUT")
(cd "$STAGE" && zip -qr "$OUT_ABS" application)
python3 - "$OUT_ABS" <<'PY'
import sys
import zipfile
archive_path = sys.argv[1]
with zipfile.ZipFile(archive_path) as archive:
    corrupt = archive.testzip()
    if corrupt:
        raise SystemExit(f"Corrupt archive entry: {corrupt}")
    names = set(archive.namelist())
    required = {
        "application/TwinsanityRintromped/mux_launch.sh",
        "application/TwinsanityRintromped/mux_lang.ini",
        "application/TwinsanityRintromped/tw-rintromped-h700-probe",
        "application/TwinsanityRintromped/device/collect-system-info.sh",
    }
    missing = sorted(required - names)
    if missing:
        raise SystemExit("Missing muxapp entries: " + ", ".join(missing))
print("Muxapp ZIP integrity and layout verified.")
PY
sha256sum "$OUT_ABS"
echo "Created $OUT_ABS"
