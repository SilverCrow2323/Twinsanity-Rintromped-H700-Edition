#!/bin/sh
# HELP: H700 graphics preflight for Twinsanity Rintromped
# GRID: Twinsanity Rintromped
. /opt/muos/script/var/func.sh || exit 1
APP_BIN="tw-rintromped-h700-probe"
SDL_BIN="tw-rintromped-h700-sdl-probe"
SHADER_BIN="tw-rintromped-h700-gles-shader-smoke"
SETUP_APP "$APP_BIN" ""
APP_DIR="/run/muos/storage/application/TwinsanityRintromped"
cd "$APP_DIR" || exit 1
mkdir -p logs
export APP_DIR
export TW_H700_REPORT="$APP_DIR/logs/egl-gles-report.txt"
export TW_H700_SDL_REPORT="$APP_DIR/logs/sdl-window-report.txt"
export TW_H700_SHADER_REPORT="$APP_DIR/logs/gles-shader-report.txt"
"$APP_DIR/device/collect-system-info.sh" "$APP_DIR/logs/muos-device-report.txt" || true
[ -x "$APP_DIR/$APP_BIN" ] || { echo "Missing $APP_BIN in $APP_DIR" >&2; exit 127; }

# Run every diagnostic independently: EGL pbuffer, NativeEE production shaders,
# and SDL's visible window path can fail for different driver/runtime reasons.
"$APP_DIR/$APP_BIN" "$@"
EGL_RC=$?
if [ -x "$APP_DIR/$SHADER_BIN" ]; then
    "$APP_DIR/$SHADER_BIN" >"$TW_H700_SHADER_REPORT" 2>&1
    SHADER_RC=$?
else
    echo "Missing $SHADER_BIN; production shader test skipped." >"$TW_H700_SHADER_REPORT"
    SHADER_RC=127
fi
if [ -x "$APP_DIR/$SDL_BIN" ]; then
    "$APP_DIR/$SDL_BIN"
    SDL_RC=$?
else
    echo "Missing $SDL_BIN; SDL presentation test skipped." >&2
    SDL_RC=127
fi
printf 'Preflight complete: EGL/GLES=%s NativeEE-shaders=%s SDL/window=%s\n' "$EGL_RC" "$SHADER_RC" "$SDL_RC"
# Diagnostics are stored in logs; return to the muOS menu without treating a
# hardware capability failure as a launcher crash.
exit 0
