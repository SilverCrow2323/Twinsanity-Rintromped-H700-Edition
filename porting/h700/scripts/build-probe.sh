#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${OUT:-"$ROOT/dist/tw-rintromped-h700-probe"}
CC=${CC:-aarch64-linux-gnu-gcc}
command -v "$CC" >/dev/null 2>&1 || { echo "Missing cross compiler: $CC" >&2; exit 2; }
TARGET=$("$CC" -dumpmachine 2>/dev/null || true)
case "$TARGET" in *aarch64*|*arm64*) ;; *) echo "Compiler is not AArch64: $TARGET" >&2; exit 2;; esac
mkdir -p "$(dirname "$OUT")"
"$CC" -std=c11 -O2 -Wall -Wextra -Werror -Wl,--as-needed "$ROOT/device/egl_gles_probe.c" -ldl -o "$OUT"
readelf -h "$OUT" | grep -q 'Class:.*ELF64'
readelf -h "$OUT" | grep -Eq 'Machine:.*AArch64'
printf 'GLIBC max: '; readelf --version-info "$OUT" | grep -o 'GLIBC_[0-9.]*' | sort -Vu | tail -n 1 || true
file "$OUT"
echo "Built $OUT for $TARGET"
