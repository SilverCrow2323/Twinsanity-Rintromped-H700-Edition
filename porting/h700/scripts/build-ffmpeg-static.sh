#!/usr/bin/env bash
# Build the exact LGPL FFmpeg subset required by the Crash Twinsanity FMV path,
# cross-compiled for AArch64 Linux. The resulting archives are linked into the
# H700 runner; muOS does not need libavcodec.so / libavutil.so / libswscale.so.
#
# Source pin and feature recipe are shared with engine/tools/ci/ffmpeg_static.sh.
# The source tarball is the FFmpeg 6.1.2 release corresponding to tag n6.1.2.
#
#   porting/h700/scripts/build-ffmpeg-static.sh <prefix>
#   FFMPEG_JOBS=2 (default: nproc)
#   FFMPEG_SOURCE=/path/to/ffmpeg-6.1.2.tar.xz (optional offline copy, SHA-256 checked)
#   FFMPEG_CROSS_PREFIX=aarch64-linux-gnu- (default)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
RECIPE="$ROOT/engine/tools/ci/ffmpeg_static.sh"
VERSION=6.1.2
TAG=n6.1.2
URL="https://ffmpeg.org/releases/ffmpeg-$VERSION.tar.xz"
SHA256=3b624649725ecdc565c903ca6643d41f33bd49239922e45c9b1442c63dca4e38
CROSS_PREFIX="${FFMPEG_CROSS_PREFIX:-aarch64-linux-gnu-}"
CC="${FFMPEG_CC:-${CROSS_PREFIX}gcc}"
CXX="${FFMPEG_CXX:-${CROSS_PREFIX}g++}"
AR="${FFMPEG_AR:-${CROSS_PREFIX}ar}"
RANLIB="${FFMPEG_RANLIB:-${CROSS_PREFIX}ranlib}"
NM="${FFMPEG_NM:-${CROSS_PREFIX}nm}"
STRIP="${FFMPEG_STRIP:-${CROSS_PREFIX}strip}"

[ -x "$RECIPE" ] || { echo "ffmpeg_h700: missing engine recipe $RECIPE" >&2; exit 1; }
RECIPE_TAG="$(env -u FFMPEG_TAG bash "$RECIPE" --print-configure | awk 'NR == 1 {print $2}')"
if [ "$RECIPE_TAG" != "$TAG" ]; then
  echo "ffmpeg_h700: engine recipe builds FFmpeg $RECIPE_TAG; this script pins $TAG ($URL, sha256 $SHA256)" >&2
  exit 1
fi

# Use the engine recipe's exact codec/parser configuration, then add only the
# Linux AArch64 cross-toolchain selectors. No GPL, non-free, network or extra
# codecs are enabled.
ARGS=()
while IFS= read -r arg; do ARGS+=("$arg"); done < <(env -u FFMPEG_TAG bash "$RECIPE" --print-args)
ARGS+=(
  --enable-cross-compile
  "--cross-prefix=$CROSS_PREFIX"
  --arch=aarch64
  --target-os=linux
  "--cc=$CC"
  "--cxx=$CXX"
  "--ar=$AR"
  "--ranlib=$RANLIB"
  "--nm=$NM"
  "--strip=$STRIP"
)
if [ -n "${FFMPEG_SYSROOT:-}" ]; then
  ARGS+=("--sysroot=$FFMPEG_SYSROOT")
fi

if [ "${1:-}" = "--print-args" ]; then
  printf '%s\n' "${ARGS[@]}"
  exit 0
fi

PREFIX="${1:?usage: build-ffmpeg-static.sh <prefix> | --print-args}"
case "$PREFIX" in /*) ;; *) PREFIX="$(pwd)/$PREFIX" ;; esac
case "$PREFIX" in *" "*) echo "ffmpeg_h700: prefix contains a space: $PREFIX" >&2; exit 1 ;; esac
for tool in "$CC" "$CXX" "$AR" "$RANLIB" "$NM" "$STRIP"; do
  command -v "$tool" >/dev/null 2>&1 || { echo "ffmpeg_h700: required cross tool not found: $tool" >&2; exit 1; }
done

if [ -n "${FFMPEG_JOBS:-}" ]; then JOBS="$FFMPEG_JOBS"
elif command -v nproc >/dev/null 2>&1; then JOBS="$(nproc)"
else JOBS=2; fi

RECORD="$({ echo "version=$VERSION"; echo "sha256=$SHA256"; printf '%s\n' "${ARGS[@]}"; })"
if [ -f "$PREFIX/lib/libavcodec.a" ] && [ -f "$PREFIX/lib/libswscale.a" ] && [ -f "$PREFIX/lib/libavutil.a" ] &&
   [ -f "$PREFIX/PS2R_FFMPEG_CONFIGURE" ] && [ "$(cat "$PREFIX/PS2R_FFMPEG_CONFIGURE")" = "$RECORD" ]; then
  echo "ffmpeg_h700: cached at $PREFIX (FFmpeg $VERSION; configure record matches)"
  touch "$PREFIX/PS2R_FFMPEG_CONFIGURE"
  exit 0
fi
if [ -f "$PREFIX/PS2R_FFMPEG_CONFIGURE" ]; then
  echo "ffmpeg_h700: stale prefix; rebuilding with the current target recipe"
  diff <(cat "$PREFIX/PS2R_FFMPEG_CONFIGURE") <(printf '%s\n' "$RECORD") | sed 's/^/  /' || true
fi

sha256_of() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else sha256sum "$1" | awk '{print $1}'; fi
}
DOWNLOADS="$PREFIX.download"
if [ -n "${FFMPEG_SOURCE:-}" ]; then
  TARBALL="$FFMPEG_SOURCE"
  [ -f "$TARBALL" ] || { echo "ffmpeg_h700: FFMPEG_SOURCE does not exist: $TARBALL" >&2; exit 1; }
  GOT="$(sha256_of "$TARBALL")"
  [ "$GOT" = "$SHA256" ] || { echo "ffmpeg_h700: wrong source SHA-256: $GOT (expected $SHA256)" >&2; exit 1; }
else
  TARBALL="$DOWNLOADS/ffmpeg-$VERSION.tar.xz"
  if [ ! -f "$TARBALL" ] || [ "$(sha256_of "$TARBALL")" != "$SHA256" ]; then
    mkdir -p "$DOWNLOADS"
    rm -f "$TARBALL" "$TARBALL.part"
    echo "ffmpeg_h700: downloading pinned FFmpeg $VERSION"
    curl -fsSL --retry 3 -o "$TARBALL.part" "$URL"
    GOT="$(sha256_of "$TARBALL.part")"
    if [ "$GOT" != "$SHA256" ]; then
      rm -f "$TARBALL.part"
      echo "ffmpeg_h700: source SHA-256 mismatch: $GOT (expected $SHA256)" >&2
      exit 1
    fi
    mv "$TARBALL.part" "$TARBALL"
  fi
fi

SRC="$PREFIX.src"
BLD="$PREFIX.build"
rm -rf "$SRC" "$BLD" "$PREFIX"
mkdir -p "$SRC" "$BLD"
tar -xJf "$TARBALL" -C "$SRC" --strip-components=1
echo "ffmpeg_h700: configure FFmpeg $VERSION (AArch64 Linux; MPEG-1/2 decoder + parser + swscale; static LGPL)"
(cd "$BLD" && "$SRC/configure" --prefix="$PREFIX" "${ARGS[@]}") > "$BLD/configure.log" 2>&1 || {
  tail -n 50 "$BLD/configure.log" >&2
  echo "ffmpeg_h700: configure failed (see $BLD/configure.log)" >&2
  exit 1
}
echo "ffmpeg_h700: make -j$JOBS"
make -C "$BLD" -j"$JOBS" > "$BLD/make.log" 2>&1 || {
  tail -n 80 "$BLD/make.log" >&2
  echo "ffmpeg_h700: build failed (see $BLD/make.log)" >&2
  exit 1
}
make -C "$BLD" install > "$BLD/install.log" 2>&1 || {
  tail -n 40 "$BLD/install.log" >&2
  echo "ffmpeg_h700: install failed" >&2
  exit 1
}

CONF="$(strings "$PREFIX/lib/libavcodec.a" | grep -- '--prefix=' | sort -u || true)"
COUNT="$(grep -c . <<< "$CONF" || true)"
if [ "$COUNT" -ne 1 ]; then
  echo "ffmpeg_h700: libavcodec.a embeds $COUNT configuration strings, expected exactly one" >&2
  exit 1
fi
if grep -qE -- '--enable-gpl|--enable-nonfree|--enable-version3' <<< "$CONF"; then
  echo "ffmpeg_h700: refusing non-LGPL FFmpeg build: $CONF" >&2
  exit 1
fi
SYMS="$("$NM" -g --defined-only "$PREFIX/lib/libavcodec.a" 2>/dev/null || true)"
for sym in ff_mpeg2video_decoder ff_mpeg1video_decoder ff_mpegvideo_parser; do
  grep -q " $sym\$" <<< "$SYMS" || { echo "ffmpeg_h700: required decoder/parser missing: $sym" >&2; exit 1; }
done

echo "$TAG" > "$PREFIX/PS2R_FFMPEG_TAG"
mkdir -p "$PREFIX/share/licenses"
cp "$SRC/COPYING.LGPLv2.1" "$PREFIX/share/licenses/FFmpeg-COPYING.LGPLv2.1.txt"
cp "$SRC/LICENSE.md" "$PREFIX/share/licenses/FFmpeg-LICENSE.md"
printf '%s\n' "$CONF" > "$PREFIX/share/licenses/FFmpeg-BUILD-CONFIGURATION.txt"
rm -rf "$SRC" "$BLD"
printf '%s\n' "$RECORD" > "$PREFIX/PS2R_FFMPEG_CONFIGURE"
echo "ffmpeg_h700: installed FFmpeg $VERSION -> $PREFIX (static AArch64 archives; LGPL v2.1+)"
