#!/bin/sh
# HELP: H700 graphics preflight for Twinsanity Rintromped
# GRID: Twinsanity Rintromped
. /opt/muos/script/var/func.sh || exit 1
APP_BIN="tw-rintromped-h700-probe"
SETUP_APP "$APP_BIN" ""
APP_DIR="/run/muos/storage/application/TwinsanityRintromped"
cd "$APP_DIR" || exit 1
mkdir -p logs
export APP_DIR
export TW_H700_REPORT="$APP_DIR/logs/egl-gles-report.txt"
"$APP_DIR/device/collect-system-info.sh" "$APP_DIR/logs/muos-device-report.txt" || true
[ -x "$APP_DIR/$APP_BIN" ] || { echo "Missing $APP_BIN in $APP_DIR" >&2; exit 127; }
exec "$APP_DIR/$APP_BIN" "$@"
