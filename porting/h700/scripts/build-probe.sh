#!/bin/sh
set -eu
ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
OUT=${OUT:-"$ROOT/dist/tw-rintromped-h700-probe"}
SDL_OUT=${SDL_OUT:-"$ROOT/dist/tw-rintromped-h700-sdl-probe"}
CC=${CC:-aarch64-linux-gnu-gcc}
command -v "$CC" >/dev/null 2>&1 || { echo "Missing cross compiler: $CC" >&2; exit 2; }
TARGET=$("$CC" -dumpmachine 2>/dev/null || true)
case "$TARGET" in *aarch64*|*arm64*) ;; *) echo "Compiler is not AArch64: $TARGET" >&2; exit 2;; esac
mkdir -p "$(dirname "$OUT")" "$(dirname "$SDL_OUT")"

"$CC" -std=c11 -O2 -Wall -Wextra -Werror -Wl,--as-needed "$ROOT/device/egl_gles_probe.c" -ldl -o "$OUT"
"$CC" -std=c11 -O2 -Wall -Wextra -Werror -Wl,--as-needed "$ROOT/device/sdl_gles_probe.c" -ldl -o "$SDL_OUT"

for binary in "$OUT" "$SDL_OUT"; do
  readelf -h "$binary" | grep -q 'Class:.*ELF64'
  readelf -h "$binary" | grep -Eq 'Machine:.*AArch64'
  printf 'GLIBC max (%s): ' "$(basename "$binary")"
  readelf --version-info "$binary" | grep -o 'GLIBC_[0-9.]*' | sort -Vu | tail -n 1 || true
  file "$binary"
done
echo "Built H700 EGL/GLES and SDL window probes for $TARGET"
