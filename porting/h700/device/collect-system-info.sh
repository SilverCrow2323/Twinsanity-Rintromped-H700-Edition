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
section ENV
for n in SDL_VIDEODRIVER SDL_AUDIODRIVER EGL_PLATFORM GBM_BACKEND DISPLAY WAYLAND_DISPLAY XDG_RUNTIME_DIR LD_LIBRARY_PATH LD_PRELOAD; do
  eval 'v=${'"$n"'-}'
  printf '%s=%s\n' "$n" "${v:-<unset>}"
done
section LIBRARIES
for d in /usr/lib /usr/lib/aarch64-linux-gnu /lib /lib/aarch64-linux-gnu /opt/muos/lib /opt/muos/share; do
  [ -d "$d" ] && find "$d" -maxdepth 2 \( -name 'libSDL2*' -o -name 'libEGL*' -o -name 'libGLES*' -o -name 'libmali*' \) -print 2>/dev/null || true
done
section END
echo 'System inventory complete.'
