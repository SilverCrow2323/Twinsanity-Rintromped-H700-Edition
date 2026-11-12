#!/bin/sh
set -eu
ZIP=\${1:-}
MAX_GLIBC=\${MAX_GLIBC:-2.31}
[ -n "$ZIP" ] && [ -f "$ZIP" ] || { echo "usage: $0 twinsanityevolved-<version>-linux-aarch64.zip" >&2; exit 2; }
for tool in unzip file readelf; do command -v "$tool" >/dev/null 2>&1 || { echo "missing tool: $tool" >&2; exit 2; }; done
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT HUP INT TERM
unzip -q "$ZIP" -d "$TMP"
BIN=$(find "$TMP" -type f -name twinsanityevolved -print -quit)
[ -n "$BIN" ] || { echo "twinsanityevolved binary not found in archive" >&2; exit 1; }
file "$BIN"
readelf -h "$BIN" | grep -E 'Class:|Machine:'
readelf -l "$BIN" | grep -E 'Requesting program interpreter' || true
printf '\nDynamic dependencies:\n'
readelf -d "$BIN" | grep NEEDED || true
MAX=$(readelf --version-info "$BIN" | grep -o 'GLIBC_[0-9.]*' | sort -Vu | tail -n 1 || true)
echo "Maximum required GLIBC symbol: $MAX"
if [ -n "$MAX" ]; then
  TOP=$(printf '%s\n' "$MAX" "GLIBC_$MAX_GLIBC" | sort -V | tail -n 1)
  if [ "$TOP" != "GLIBC_$MAX_GLIBC" ]; then
    echo "WARNING: binary needs newer GLIBC than $MAX_GLIBC; do not assume it will launch on muOS." >&2
    exit 3
  fi
fi
