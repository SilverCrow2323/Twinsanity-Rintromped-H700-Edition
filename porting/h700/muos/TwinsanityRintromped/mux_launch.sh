#!/bin/sh
# HELP: Twinsanity Rintromped - H700 Edition
# GRID: Twinsanity Rintromped
. /opt/muos/script/var/func.sh || exit 1

APP_DIR="/run/muos/storage/application/TwinsanityRintromped"
GAME_BIN="twinsanityevolved"
APP_BIN="tw-rintromped-h700-probe"
SDL_BIN="tw-rintromped-h700-sdl-probe"
SHADER_BIN="tw-rintromped-h700-gles-shader-smoke"

# Prefer the real game executable when a full application package is installed.
# The diagnostic-only .muxapp keeps its existing preflight behavior.
if [ -x "$APP_DIR/$GAME_BIN" ]; then
    APP_BIN="$GAME_BIN"
fi
SETUP_APP "$APP_BIN" ""
cd "$APP_DIR" || exit 1
mkdir -p logs

if [ "$APP_BIN" = "$GAME_BIN" ]; then
    # NativeEE reads the user's disc-image.txt beside the executable. muOS has no
    # zenity/kdialog picker, so seed it from game.iso only when the saved selection
    # is absent or points to a file that no longer exists. Never alter the ISO.
    DISC_OK=0
    DISC_IMAGE=""
    if [ -s "$APP_DIR/disc-image.txt" ]; then
        IFS= read -r DISC_IMAGE < "$APP_DIR/disc-image.txt" || true
        case "$DISC_IMAGE" in
            /*) [ -f "$DISC_IMAGE" ] && DISC_OK=1 ;;
            "") DISC_OK=0 ;;
            *)  [ -f "$APP_DIR/$DISC_IMAGE" ] && DISC_OK=1 ;;
        esac
    fi
    if [ "$DISC_OK" -ne 1 ] && [ -f "$APP_DIR/game.iso" ]; then
        printf '%s\n' "game.iso" > "$APP_DIR/.disc-image.txt.tmp"
        mv -f "$APP_DIR/.disc-image.txt.tmp" "$APP_DIR/disc-image.txt"
        DISC_OK=1
    fi
    if [ "$DISC_OK" -ne 1 ]; then
        echo "No valid disc image. Put your own game.iso in $APP_DIR or restore disc-image.txt." >&2
        exit 2
    fi

    # The physical preflight selected SDL's Mali backend on this muOS build.
    export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-mali}"
    exec "$APP_DIR/$GAME_BIN" "$@" >> "$APP_DIR/logs/game-launch.log" 2>&1
fi

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
