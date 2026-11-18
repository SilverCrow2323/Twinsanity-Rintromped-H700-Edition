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
# Preserve the selected muOS input contract for support reports. The mapping
# contains button indices only; no credentials or user content are recorded.
{
    printf 'muOS version: %s\n' "$(cat /opt/muos/config/system/version 2>/dev/null || echo unknown)"
    printf 'muOS build: %s\n' "$(cat /opt/muos/config/system/build 2>/dev/null || echo unknown)"
    printf 'muOS board: %s\n' "$(cat /opt/muos/device/config/board/name 2>/dev/null || echo unknown)"
    printf 'muOS controller selection: %s\n' "$(cat /run/muos/controller 2>/dev/null || echo system)"
    printf 'SDL controller DB: %s\n' "${SDL_GAMECONTROLLERCONFIG_FILE:-<unset>}"
    printf 'SDL active mapping: %s\n' "${SDL_GAMECONTROLLERCONFIG:-<unset>}"
} >> "$APP_DIR/logs/game-launch.log"


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
    APP_ROOT="$(pwd -P)"
    resolve_disc_image() {
        candidate="$1"
        case "$candidate" in
            /*) ;;
            *) candidate="$APP_ROOT/$candidate" ;;
        esac

        [ -f "$candidate" ] || return 1
        [ ! -L "$candidate" ] || return 1
        candidate_dir="$(dirname "$candidate")" || return 1
        candidate_name="$(basename "$candidate")" || return 1
        resolved_dir="$(CDPATH= cd -P "$candidate_dir" 2>/dev/null && pwd -P)" || return 1
        case "$resolved_dir" in
            "$APP_ROOT"|"$APP_ROOT"/*) ;;
            *) return 1 ;;
        esac

        resolved_path="$resolved_dir/$candidate_name"
        [ -f "$resolved_path" ] && [ ! -L "$resolved_path" ] || return 1
        printf '%s\n' "$resolved_path"
    }

    DISC_OK=0
    DISC_IMAGE=""
    DISC_PATH=""
    if [ -s "$APP_DIR/disc-image.txt" ]; then
        IFS= read -r DISC_IMAGE < "$APP_DIR/disc-image.txt" || true
        if [ -n "$DISC_IMAGE" ]; then
            DISC_PATH="$(resolve_disc_image "$DISC_IMAGE" 2>/dev/null)" || DISC_PATH=""
            if [ -n "$DISC_PATH" ]; then
                DISC_OK=1
            else
                printf 'Rejected saved disc selection (missing, symlinked, or outside app root): %s\n' "$DISC_IMAGE" >> "$APP_DIR/logs/game-launch.log"
            fi
        fi
    fi
    if [ "$DISC_OK" -ne 1 ]; then
        DISC_PATH="$(resolve_disc_image "game.iso" 2>/dev/null)" || DISC_PATH=""
        if [ -n "$DISC_PATH" ]; then
            DISC_IMAGE="game.iso"
            DISC_TMP="$(mktemp "$APP_DIR/.disc-image.txt.tmp.XXXXXX")" || exit 1
            if ! printf '%s\n' "$DISC_IMAGE" > "$DISC_TMP"; then
                rm -f "$DISC_TMP"
                exit 1
            fi
            if ! mv -f "$DISC_TMP" "$APP_DIR/disc-image.txt"; then
                rm -f "$DISC_TMP"
                exit 1
            fi
            DISC_OK=1
        fi
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

    # This package ships the standalone game runner built from runner/main.cpp.
    # That CLI does not accept --launcher. The ImGui launcher under engine/app/host
    # belongs to a separate NativeEE host target and is not linked into this runner.
    # Passing --launcher here makes the real runner print Usage() and exit with status 2.
    # Keep the hand-off to the known-supported CLI until the menu is integrated properly.
    set -- --iso "$DISC_PATH"
    {
        printf 'Startup UI: not bundled in this runner; launching the selected disc directly\\n'
        printf 'Runner arguments:'
        for arg in "$@"; do printf ' <%s>' "$arg"; done
        printf '\\n'
    } >> "$APP_DIR/logs/game-launch.log"
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
