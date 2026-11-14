#!/bin/sh
set -eu
OUT=${1:-"${TW_H700_SYSINFO:-./muos-device-report.txt}"}
mkdir -p "$(dirname "$OUT")"
exec >"$OUT" 2>&1
section(){ printf '\n===== %s =====\n' "$1"; }
section BASIC
printf 'date: '; date 2>/dev/null || true
printf 'uname: '; uname -a 2>/dev/null || true
printf 'uid: '; id 2>/dev/null || true
section OS_DEVICE
for f in /etc/os-release /etc/muos-release /proc/device-tree/model /proc/cpuinfo /proc/meminfo; do
  [ -r "$f" ] || continue
  echo "--- $f"
  if [ "$f" = /proc/cpuinfo ]; then grep -vi '^[[:space:]]*Serial[[:space:]]*:' "$f" || true
  else cat "$f" 2>/dev/null | tr '\000' '\n'; fi
done
section DISPLAY_GPU
for f in /sys/class/graphics/fb0/name /sys/class/graphics/fb0/modes /sys/class/devfreq/gpu/name /sys/class/devfreq/gpu/cur_freq; do
  [ -r "$f" ] && { echo "--- $f"; cat "$f"; }
done
for n in /dev/fb0 /dev/dri /dev/mali0 /dev/mali /dev/input /dev/snd; do [ -e "$n" ] && ls -ld "$n" 2>/dev/null || true; done
section MUOS_INPUT
for f in \
  /opt/muos/config/system/version \
  /opt/muos/config/system/build \
  /opt/muos/device/config/board/name \
  /opt/muos/device/config/sdl/name \
  /opt/muos/config/settings/remap/layout \
  /run/muos/controller; do
  [ -r "$f" ] && { echo "--- $f"; cat "$f"; }
done
for f in /usr/lib/gamecontrollerdb.txt /usr/lib32/gamecontrollerdb.txt; do
  [ -r "$f" ] || continue
  echo "--- $f (muOS-Keys rows)"
  grep -i 'muOS-Keys' "$f" || true
done
section ENV
for n in SDL_VIDEODRIVER SDL_AUDIODRIVER EGL_PLATFORM GBM_BACKEND DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR \
  SDL_GAMECONTROLLERCONFIG_FILE SDL_GAMECONTROLLERCONFIG LD_LIBRARY_PATH LD_PRELOAD; do
  eval 'v=${'"$n"'-}'
  printf '%s=%s\n' "$n" "${v:-<unset>}"
done
section LIBRARIES
for d in /usr/lib /usr/lib/aarch64-linux-gnu /lib /lib/aarch64-linux-gnu /opt/muos/lib /opt/muos/share; do
  [ -d "$d" ] && find "$d" -maxdepth 2 \( \
    -name 'libSDL2*' -o -name 'libEGL*' -o -name 'libGLES*' -o -name 'libmali*' -o \
    -name 'libavcodec*' -o -name 'libavutil*' -o -name 'libswscale*' -o \
    -name 'libstdc++.so*' -o -name 'libgcc_s.so*' \
  \) -print 2>/dev/null || true
done
if command -v ldconfig >/dev/null 2>&1; then
  echo '--- ldconfig selected graphics / multimedia libraries'
  ldconfig -p 2>/dev/null | grep -E 'lib(SDL2|EGL|GLESv2|mali|avcodec|avutil|swscale|stdc\+\+|gcc_s)\.so' || true
fi
section END
echo 'System inventory complete.'
