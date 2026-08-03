#!/bin/bash
# Auto-repair outward symlinks removed by mobile app. Run via cron (sudo).
set -euo pipefail

[ "$(id -u)" -eq 0 ] || exit 0

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS="${SCRIPT_DIR}/phase-docs"
SCAN="${DOCS}/01-host-scan.json"
CORE="${DOCS}/03-nextcloud-core.json"
[ -f "${SCAN}" ] && [ -f "${CORE}" ] || exit 0

CURRENT_USER=$(python3 -c "import json; print(json.load(open('${SCAN}'))['current_user'])")
NC_USER=$(python3 -c "import json; d=json.load(open('${SCAN}')); print(d.get('nc_username', d['current_user']))")
CURRENT_HOME=$(python3 -c "import json; print(json.load(open('${SCAN}'))['current_home'])")
WEB_ROOT=$(python3 -c "import json; print(json.load(open('${CORE}'))['web_root'])")
DATA_DIR=$(python3 -c "import json; print(json.load(open('${CORE}'))['data_dir'])")
PHP_SERIES=$(python3 -c "import json; d=json.load(open('${SCAN}')); print(d['install_plan']['php_series'])")
NC_VERSION=$(python3 -c "import json; d=json.load(open('${SCAN}')); print(d['install_plan']['nextcloud_version'])")
PHP_BIN=$(nc_php_bin "${PHP_SERIES}")
CONFIG="${WEB_ROOT}/config/config.php"
NC_FILES="${DATA_DIR}/${NC_USER}/files"
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
LOG="/tmp/nextcloud-symlink-guardian.log"
changed=0

log() { echo "[$(date '+%F %T')] $*" >> "${LOG}"; }

repair_link() {
  local d="$1"
  local target="${CURRENT_HOME}/${d}"
  local link="${NC_FILES}/${d}"
  mkdir -p "${target}"
  if [ -L "${link}" ] && [ "$(readlink "${link}")" = "${target}" ]; then
    return 0
  fi
  rm -rf "${link}"
  sudo -u www-data ln -s "${target}" "${link}"
  log "relinked ${d} → ${target}"
  changed=1
}

mkdir -p "${NC_FILES}"
touch "${NC_FILES}/.ocdata" 2>/dev/null || true
chown www-data:www-data "${NC_FILES}" "${NC_FILES}/.ocdata" 2>/dev/null || true

for d in "${FOLDERS[@]}"; do
  repair_link "${d}"
done

if [ -d "${CURRENT_HOME}/Pictures" ]; then
  if [ ! -L "${NC_FILES}/Photos" ] || [ "$(readlink "${NC_FILES}/Photos")" != "${CURRENT_HOME}/Pictures" ]; then
    rm -rf "${NC_FILES}/Photos"
    sudo -u www-data ln -sfn "${CURRENT_HOME}/Pictures" "${NC_FILES}/Photos"
    log "relinked Photos → Pictures"
    changed=1
  fi
fi

nc_enable_outward_symlinks "${WEB_ROOT}" "${PHP_BIN}" "${NC_VERSION}" 2>/dev/null || true
nc_patch_config_allow_symlinks "${CONFIG}" 2>/dev/null || true

if [ "${changed}" -eq 1 ]; then
  sudo -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" files:scan "${NC_USER}" >> "${LOG}" 2>&1 || true
  log "scan complete after relink"
fi
