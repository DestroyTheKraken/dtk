#!/bin/bash
# Hub backup → ~/Backups/nas-export/ (invoked via sudo from cron).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SCAN_FILE="${SCRIPT_DIR}/phase-docs/01-host-scan.json"

if [ "$(id -u)" -ne 0 ]; then
  exec sudo -n "$(readlink -f "$0")" "$@"
fi

if [ -f "${SCAN_FILE}" ]; then
  OWNER_HOME=$(python3 -c "import json; print(json.load(open('${SCAN_FILE}'))['current_home'])")
  OWNER_UID=$(python3 -c "import json; print(json.load(open('${SCAN_FILE}'))['user_uid'])")
else
  OWNER_HOME=$(getent passwd 1000 | cut -d: -f6)
  OWNER_UID=1000
fi

STAMP="$(date +%Y%m%d-%H%M)"
DEST="${OWNER_HOME}/Backups/nas-export"
HOST_SLUG="$(hostname -s | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-')"
ARCHIVE="${DEST}/${HOST_SLUG}-nc-${STAMP}.tar.gz"
TMP="$(mktemp -d)"
WEB_ROOT="/var/www/nextcloud"
DATA_ROOT="/var/lib/nextcloud"

mkdir -p "${DEST}"
chown "${OWNER_UID}:${OWNER_UID}" "${DEST}"
trap 'rm -rf "${TMP}"' EXIT

log() { printf '[%s] %s\n' "$(date '+%F %T')" "$*"; }

log "Dumping MariaDB nextcloud..."
mysqldump --single-transaction nextcloud > "${TMP}/nextcloud.sql"

log "Copying Nextcloud config..."
cp -a "${WEB_ROOT}/config" "${TMP}/nc-config"

log "Archiving data directory..."
tar -czf "${TMP}/nc-data.tar.gz" -C "${DATA_ROOT}" data

log "Writing ${ARCHIVE}..."
tar -czf "${ARCHIVE}" -C "${TMP}" nextcloud.sql nc-config nc-data.tar.gz
chown "${OWNER_UID}:${OWNER_UID}" "${ARCHIVE}"
ln -sfn "$(basename "${ARCHIVE}")" "${DEST}/latest.tar.gz"
chown -h "${OWNER_UID}:${OWNER_UID}" "${DEST}/latest.tar.gz"

ls -1t "${DEST}"/*-nc-*.tar.gz 2>/dev/null | tail -n +8 | xargs -r rm -f

log "Done: ${ARCHIVE} ($(du -h "${ARCHIVE}" | cut -f1))"
