#!/bin/sh
# Host-only checks; these are not an H700 runtime test.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
REPO_ROOT=$(CDPATH= cd -- "$ROOT/../.." && pwd)
cd "$ROOT"
# Guard the muOS archive root: the app directory must be the first path component.
grep -q 'APP="$STAGE/TwinsanityRintromped"' scripts/package-muxapp.sh
grep -q 'zip -qr "$TMP_ARCHIVE" TwinsanityRintromped' scripts/package-muxapp.sh
grep -q 'mv -f "$TMP_ARCHIVE" "$OUT_ABS"' scripts/package-muxapp.sh
if grep -q 'application/TwinsanityRintromped' scripts/package-muxapp.sh; then echo 'Legacy nested muxapp layout detected' >&2; exit 1; fi
if grep -R -n -F '\${' scripts device muos --exclude=test-kit.sh; then echo 'Found escaped shell expansion' >&2; exit 1; fi
for f in scripts/*.sh muos/TwinsanityRintromped/*.sh device/*.sh; do [ -f "$f" ] && sh -n "$f"; done
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
with zipfile.ZipFile(sys.argv[1]) as archive:
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

# Keep Ubuntu 22.04 multiarch indices architecture-specific: amd64 mirrors do
# not publish arm64 Packages files; arm64 must use ports.ubuntu.com.
WORKFLOW="$REPO_ROOT/.github/workflows/rintromped-h700.yml"
python3 - "$WORKFLOW" <<'PY'
from pathlib import Path
import re
import sys

workflow = Path(sys.argv[1]).read_text(encoding="utf-8")
match = re.search(
    r"^  gles-renderer-compile:\s*\n(.*?)(?=^  [A-Za-z0-9_-]+:\s*$|\Z)",
    workflow,
    re.MULTILINE | re.DOTALL,
)
if not match:
    raise SystemExit("Missing gles-renderer-compile job")
job = match.group(1)
required = (
    "dpkg --add-architecture arm64",
    "deb [arch=amd64] http://archive.ubuntu.com/ubuntu",
    "deb [arch=amd64] http://security.ubuntu.com/ubuntu",
    "deb [arch=arm64] https://ports.ubuntu.com/ubuntu-ports",
    "sudo rm -f /etc/apt/sources.list.d/ubuntu.sources",
    "sudo apt-get update",
)
missing = [value for value in required if value not in job]
if missing:
    raise SystemExit("AArch64 apt source configuration incomplete: " + ", ".join(missing))
print("AArch64 multiarch apt sources route arm64 through Ubuntu Ports.")
PY


# The GLES mip synthesis loop rewrites cw/ch after each BoxHalve iteration.
# They must remain mutable (Windows clang-cl and AArch64 GCC both enforce this).
if grep -Eq '^[[:space:]]*const[[:space:]]+GLint[[:space:]]+(cw|ch)[[:space:]]*=' "$REPO_ROOT/engine/engine/render/backends/gl/gl_device.cpp"; then
    echo "Generated mip dimensions cw/ch must be mutable" >&2
    exit 1
fi


# The cross renderer compile must use the AArch64 SDL development package and
# its multiarch generated config header, not only the host amd64 SDL headers.
grep -q 'libsdl2-dev:arm64' "$WORKFLOW"
grep -q 'SDL2/_real_SDL_config.h' "$REPO_ROOT/porting/h700/renderer/CMakeLists.txt"
grep -q 'TE_SDL2_TARGET_CONFIG_INCLUDE_DIR' "$REPO_ROOT/porting/h700/renderer/CMakeLists.txt"


# Cross-compiled SDL sources must not resolve the host amd64-generated config.
grep -q 'libsdl2-dev:arm64' "$WORKFLOW"
grep -q 'SDL2/_real_SDL_config.h' "$REPO_ROOT/porting/h700/renderer/CMakeLists.txt"
grep -q 'TE_SDL2_TARGET_CONFIG_INCLUDE_DIR' "$REPO_ROOT/porting/h700/renderer/CMakeLists.txt"

echo 'Host checks passed (device and AArch64 runtime tests pending).'
