#!/bin/sh
# HELP: Twinsanity Rintromped - H700 Edition
# GRID: Twinsanity Rintromped

# The two overrides keep the launcher testable on a host; muOS uses its normal
# paths and SETUP_APP implementation.
MUOS_FUNC_SH="${TW_H700_MUOS_FUNC_SH:-/opt/muos/script/var/func.sh}"
. "$MUOS_FUNC_SH" || exit 1

APP_DIR="${TW_H700_APP_DIR:-/run/muos/storage/application/TwinsanityRintromped}"
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

# A one-shot opt-in: create logs/performance-diagnostics.once to collect low-overhead
# CPU samples plus the renderer/build timing census for the next game launch only.
PERF_MARKER="$APP_DIR/logs/performance-diagnostics.once"
if [ -f "$PERF_MARKER" ]; then
    rm -f "$PERF_MARKER"
    export TE_PROF=1
    export TE_PROF_US=2000
    export TE_PROF_EVERY=120
    export TE_PROF_ROWS=12
    export TE_GFX_SUMMARY_EVERY=120
    printf 'Performance diagnostics: one-shot CPU/render profiler enabled (2 ms sampling, 120 presents/report)\n' >> "$APP_DIR/logs/game-launch.log"
fi

if [ "$APP_BIN" = "$GAME_BIN" ]; then
    # NativeEE requires --iso <image>. The launcher stores the user's selection
    # beside the executable and passes its resolved path explicitly; merely
    # writing disc-image.txt is not enough for the runner's command-line parser.
    # If the saved path is missing, seed it from game.iso without touching it.
    DISC_OK=0
    DISC_IMAGE=""
    DISC_PATH=""
    if [ -s "$APP_DIR/disc-image.txt" ]; then
        IFS= read -r DISC_IMAGE < "$APP_DIR/disc-image.txt" || true
        case "$DISC_IMAGE" in
            /*) DISC_PATH="$DISC_IMAGE" ;;
            "") DISC_PATH="" ;;
            *)  DISC_PATH="$APP_DIR/$DISC_IMAGE" ;;
        esac
        [ -f "$DISC_PATH" ] && DISC_OK=1
    fi
    if [ "$DISC_OK" -ne 1 ] && [ -f "$APP_DIR/game.iso" ]; then
        DISC_IMAGE="game.iso"
        DISC_PATH="$APP_DIR/$DISC_IMAGE"
        printf '%s\n' "$DISC_IMAGE" > "$APP_DIR/.disc-image.txt.tmp"
        mv -f "$APP_DIR/.disc-image.txt.tmp" "$APP_DIR/disc-image.txt"
        DISC_OK=1
    fi
    if [ "$DISC_OK" -ne 1 ]; then
        echo "No valid disc image. Put your own game.iso in $APP_DIR or restore disc-image.txt." >&2
        exit 2
    fi

    # The physical preflight selected SDL's Mali backend on this muOS build.
    export SDL_VIDEODRIVER="${SDL_VIDEODRIVER:-mali}"
    {
        printf 'Launching %s\n' "$GAME_BIN"
        printf 'Disc image: %s\n' "$DISC_PATH"
        printf 'SDL video driver: %s\n' "$SDL_VIDEODRIVER"
        printf 'Runner argv[1]: --iso\n'
        printf 'Runner argv[2]: %s\n' "$DISC_PATH"
        printf 'Launcher arguments ignored: %s\n' "$#"
    } >> "$APP_DIR/logs/game-launch.log"

    # Record the global hotkey plumbing before handing control to NativeEE.
    # SETUP_APP writes the foreground_process consumed by muOS's Force Quit
    # action; muhotkey itself is a separate system daemon, not an SDL event
    # handler owned by this game process.
    HOTKEY_PIDS="$(pgrep -x muhotkey 2>/dev/null || true)"
    FOREGROUND_PROCESS="$(GET_VAR "config" "system/foreground_process" 2>/dev/null || true)"
    {
        printf 'muOS foreground_process: %s\n' "$FOREGROUND_PROCESS"
        if [ -n "$HOTKEY_PIDS" ]; then
            printf 'muOS muhotkey daemon PID(s): %s\n' "$HOTKEY_PIDS"
        else
            printf 'WARNING: muhotkey daemon not visible at game handoff\n'
        fi
    } >> "$APP_DIR/logs/game-launch.log"

    # Boot straight into the selected game image. The optional Qt pre-launch
    # screen is deliberately skipped on the H700 path: muOS already owns
    # application navigation, and this framebuffer-only target should not
    # depend on the extra Qt launcher to reach gameplay.
    printf 'Startup UI: skipped; launching the selected disc directly\n' >> "$APP_DIR/logs/game-launch.log"
    exec "$APP_DIR/$GAME_BIN" --iso "$DISC_PATH" >> "$APP_DIR/logs/game-launch.log" 2>&1
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
