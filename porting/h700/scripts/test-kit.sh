#!/bin/sh
# Host-only checks; these are not an H700 runtime test.
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"
for f in scripts/*.sh muos/TwinsanityRintromped/*.sh device/*.sh; do [ -f "$f" ] && sh -n "$f"; done
TMP=$(mktemp -d); trap 'rm -rf "$TMP"' EXIT HUP INT TERM
cc -std=c11 -O2 -Wall -Wextra -Werror device/egl_gles_probe.c -ldl -o "$TMP/probe-host"
set +e
TW_H700_REPORT="$TMP/report.txt" "$TMP/probe-host" >"$TMP/stdout.txt" 2>&1
rc=$?
set -e
case "$rc" in 0|2|3|5) ;; *) cat "$TMP/stdout.txt" >&2; exit 1;; esac
[ -s "$TMP/report.txt" ]
grep -q 'H700 EGL/GLES probe' "$TMP/report.txt"
if PROBE_BIN="$TMP/probe-host" scripts/package-muxapp.sh "$TMP/should-not-exist.muxapp" >/dev/null 2>&1; then echo 'Accepted non-AArch64 binary' >&2; exit 1; fi
[ ! -e "$TMP/should-not-exist.muxapp" ]
echo 'Host checks passed (device and AArch64 runtime tests pending).'
