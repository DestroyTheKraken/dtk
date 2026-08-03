#!/bin/bash
# Standalone watcher (will be customized by phase-05 with actual values).
# For manual use after installation:
#   1. Replace placeholders below
#   2. nohup ./watch-and-scan.sh > /tmp/nextcloud-watch.log 2>&1 &

set -euo pipefail

WEB_ROOT="/var/www/nextcloud"
NC_USER="REPLACE_WITH_USER"
HOME_DIR="/home/REPLACE_WITH_USER"
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)

log() { echo "[$(date '+%F %T')] $*"; }

command -v inotifywait >/dev/null || { echo "Need inotify-tools"; exit 1; }

WATCH_PATHS=()
for d in "${FOLDERS[@]}"; do
    p="$HOME_DIR/$d"
    [ -d "$p" ] && WATCH_PATHS+=("$p")
done

inotifywait -m -r -e create,modify,delete,move,close_write --format '%w%f %e' "${WATCH_PATHS[@]}" |
while read -r path event; do
    for d in "${FOLDERS[@]}"; do
        if [[ "$path" == "$HOME_DIR/$d"* ]]; then
            log "Change detected in $d"
            sudo -u www-data php "$WEB_ROOT/occ" files:scan "$NC_USER" --path="/$d" --quiet 2>/dev/null || true
            break
        fi
    done
done