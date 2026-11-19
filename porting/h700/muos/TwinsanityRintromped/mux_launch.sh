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
    # Keep decoded RGBA textures from piling up behind the GLES render thread on the 1 GB H700.
    # Mode 2 keeps eager IDs but decodes/makes each texture only when its first draw needs it.
    # Respect an explicit user override for diagnostics.
    if [ -z "${TE_GFX_EAGER_TEXTURES+x}" ]; then
        export TE_GFX_EAGER_TEXTURES=2
        printf 'Texture scheduling: decode on first draw (H700 default, TE_GFX_EAGER_TEXTURES=2)\n' >> "$APP_DIR/logs/game-launch.log"
    else
        printf 'Texture scheduling override: TE_GFX_EAGER_TEXTURES=%s\n' "$TE_GFX_EAGER_TEXTURES" >> "$APP_DIR/logs/game-launch.log"
    fi
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
        printf 'Startup UI: not bundled in this runner; launching the selected disc directly\n'
        printf 'Runner arguments:'
        for arg in "$@"; do printf ' <%s>' "$arg"; done
        printf '\n'
    } >> "$APP_DIR/logs/game-launch.log"
    # Mali kbase can account GPU-backed pages to the client process without those
    # pages appearing in ordinary smaps VMAs. Read-only debugfs snapshots, when the
    # firmware exposes them, complement procfs and may identify the context pools.
    capture_mali_debugfs() {
        debug_reason="$1"
        debug_found=0
        for debug_root in /sys/kernel/debug/mali0 /sys/kernel/debug/mali /sys/kernel/debug/mali_kbase; do
            [ -d "$debug_root" ] || continue
            debug_found=1
            printf '[mali] debugfs snapshot=%s root=%s pid=%s\n' "$debug_reason" "$debug_root" "$sample_pid"
            find "$debug_root" -maxdepth 4 -type f \( \
                -name mem_pool_size -o -name mem_pool_max_size -o \
                -name lp_mem_pool_size -o -name lp_mem_pool_max_size -o \
                -name mem_profile -o -name gpu_memory -o -name memory_usage -o \
                -name ctx_num \
            \) -print 2>/dev/null | while IFS= read -r debug_file; do
                case "$debug_file" in
                    */"$sample_pid"/*|*/mem_pool_size|*/mem_pool_max_size|*/lp_mem_pool_size|*/lp_mem_pool_max_size|*/gpu_memory|*/memory_usage|*/ctx_num) ;;
                    *) continue ;;
                esac
                printf '[mali-debugfs] %s\n' "$debug_file"
                if [ -r "$debug_file" ]; then
                    head -c 4096 "$debug_file" 2>/dev/null || true
                    printf '\n'
                else
                    printf '[unreadable]\n'
                fi
            done
        done
        if [ "$debug_found" -eq 0 ]; then
            printf '[mali] debugfs unavailable (not mounted or no known kbase root)\n'
        fi
    }

    # Sample the game's live memory from procfs while it runs. H700's OOM report
    # shows kbase GPU pages in RSS that are absent from smaps; pair procfs with
    # read-only Mali debugfs snapshots at startup and each 128 MiB RSS growth step.
    sample_runner_memory() {
        sample_pid="$1"
        sample_seconds="$TW_H700_MEM_SAMPLE_SECONDS"
        [ -n "$sample_seconds" ] || sample_seconds=5
        case "$sample_seconds" in *[!0-9]*) sample_seconds=5 ;; esac
        [ "$sample_seconds" -ge 1 ] 2>/dev/null || sample_seconds=5
        sample_count=0
        last_map_bucket=0
        sleep_pid=""
        trap 'if [ -n "$sleep_pid" ]; then kill "$sleep_pid" 2>/dev/null || true; fi; exit 0' TERM INT
        printf '[memory] runner pid=%s sampler interval=%ss (procfs + optional Mali debugfs)\n' "$sample_pid" "$sample_seconds"
        capture_mali_debugfs startup
        while kill -0 "$sample_pid" 2>/dev/null; do
            status_file="/proc/$sample_pid/status"
            [ -r "$status_file" ] || break
            fields="$(awk '
                $1 == "VmRSS:" { rss = $2 }
                $1 == "RssAnon:" { anon = $2 }
                $1 == "RssFile:" { file = $2 }
                $1 == "RssShmem:" { shmem = $2 }
                $1 == "VmSwap:" { swap = $2 }
                END { printf "%d %d %d %d %d\n", rss, anon, file, shmem, swap }
            ' "$status_file" 2>/dev/null)"
            set -- $fields
            rss="${1:-0}"
            rss_anon="${2:-0}"
            rss_file="${3:-0}"
            rss_shmem="${4:-0}"
            vm_swap="${5:-0}"
            {
                printf '[memory] epoch=%s pid=%s VmRSS=%skB RssAnon=%skB RssFile=%skB RssShmem=%skB VmSwap=%skB\n' \
                    "$(date +%s 2>/dev/null || echo 0)" "$sample_pid" "$rss" "$rss_anon" "$rss_file" "$rss_shmem" "$vm_swap"
                printf '[memory] host '
                awk '
                    $1 == "MemAvailable:" || $1 == "SwapFree:" || $1 == "SwapTotal:" {
                        key = $1
                        sub(/:$/, "", key)
                        printf "%s=%s%s ", key, $2, $3
                    }
                    END { print "" }
                ' /proc/meminfo 2>/dev/null
                if [ -r "/proc/$sample_pid/smaps_rollup" ]; then
                    printf '[memory] smaps_rollup '
                    awk '
                        $1 == "Rss:" || $1 == "Pss:" || $1 == "Pss_Anon:" || $1 == "Pss_File:" ||
                        $1 == "Shared_Clean:" || $1 == "Shared_Dirty:" || $1 == "Private_Clean:" ||
                        $1 == "Private_Dirty:" || $1 == "Anonymous:" || $1 == "Swap:" {
                            printf "%s=%s%s ", $1, $2, $3
                        }
                        END { print "" }
                    ' "/proc/$sample_pid/smaps_rollup" 2>/dev/null
                fi
            }
            sample_count=$((sample_count + 1))
            # At every additional 128 MiB of file-backed RSS, capture the ten
            # largest mappings once. This is event-triggered, not every sample.
            if [ "$rss_file" -ge 131072 ] 2>/dev/null; then
                map_bucket=$((rss_file / 131072))
                if [ "$map_bucket" -gt "$last_map_bucket" ]; then
                    printf '[memory] largest mappings at RssFile=%skB (bucket=%s):\n' "$rss_file" "$map_bucket"
                    if [ -r "/proc/$sample_pid/smaps" ]; then
                        awk '
                            function emit() { if (map != "") printf "%10d\t%s\n", rss, map }
                            /^[[:xdigit:]]+-[[:xdigit:]]+ / { emit(); map = $0; rss = 0; next }
                            $1 == "Rss:" { rss = $2 }
                            END { emit() }
                        ' "/proc/$sample_pid/smaps" 2>/dev/null | sort -nr | head -n 10 | sed 's/^/[memory-map] /' || true
                    else
                        printf '[memory] smaps unavailable for pid=%s\n' "$sample_pid"
                    fi
                    capture_mali_debugfs "rssfile-bucket-$map_bucket"
                    last_map_bucket="$map_bucket"
                fi
            fi
            sleep "$sample_seconds" &
            sleep_pid=$!
            wait "$sleep_pid" 2>/dev/null || true
            sleep_pid=""
        done
        printf '[memory] sampler end: pid=%s samples=%s\n' "$sample_pid" "$sample_count"
    }

    # Keep the wrapper alive while the runner executes so its termination is observable.
    # A shell return code >=128 commonly represents termination by signal (128 + signal).
    "$APP_DIR/$GAME_BIN" "$@" >> "$APP_DIR/logs/game-launch.log" 2>&1 &
    GAME_PID=$!
    ( sample_runner_memory "$GAME_PID" ) >> "$APP_DIR/logs/game-launch.log" 2>&1 &
    MEMORY_PID=$!
    wait "$GAME_PID"
    GAME_RC=$?
    kill "$MEMORY_PID" 2>/dev/null || true
    wait "$MEMORY_PID" 2>/dev/null || true
    {
        printf '\n===== Twinsanity runner terminated =====\n'
        printf 'Runner exit status: %s\n' "$GAME_RC"
        if [ "$GAME_RC" -ge 128 ]; then
            printf 'Possible terminating signal: %s (exit status minus 128)\n' "$((GAME_RC - 128))"
        fi
        printf 'Kernel log tail after runner exit:\n'
        dmesg 2>&1 | tail -n 100
        printf '===== End runner termination report =====\n'
    } >> "$APP_DIR/logs/game-launch.log"
    exit "$GAME_RC"
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
