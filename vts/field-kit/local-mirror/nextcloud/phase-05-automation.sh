#!/bin/bash
#
# Phase 5: Watcher, sync cron, Apache :8080, Tailscale serve, symlink guardian.
# All configuration driven by install_plan from Phase 1.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

DOCS_DIR="$(nc_docs_dir)"
SCAN_FILE="${DOCS_DIR}/01-host-scan.json"

if [ ! -f "${SCAN_FILE}" ]; then
  echo "ERROR: Run phase-01 first."
  exit 1
fi

CURRENT_USER=$(nc_read_scan_field current_user)
CURRENT_HOME=$(nc_read_scan_field current_home)
WEB_ROOT=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d.get('recommendations',{}).get('web_root','/var/www/nextcloud'))")
PHP_SERIES=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['php_series'])")
NC_VERSION=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['nextcloud_version'])")
BACKEND_HOST=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['apache']['backend_host'])")
BACKEND_PORT=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['apache']['backend_port'])")
SYNC_INTERVAL=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['automation']['sync_cron_minutes'])")
GUARDIAN_INTERVAL=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['automation']['symlink_guardian_minutes'])")
TS_BACKEND=$(python3 -c "import json; d=json.load(open('${SCAN_FILE}')); print(d['install_plan']['tailscale']['serve_backend'])")

NC_USER=$(nc_read_scan_nc_username "${DOCS_DIR}")
NC_USER=$(nc_resolve_nc_user "${NC_USER}" "/var/lib/nextcloud/data" "${DOCS_DIR}" "${WEB_ROOT}")
PHP_BIN=$(nc_php_bin "${PHP_SERIES}")

FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)
WATCHER_SCRIPT="${SCRIPT_DIR}/watch-and-scan.sh"
GUARDIAN_SCRIPT="${SCRIPT_DIR}/symlink-guardian.sh"
OUTPUT_FILE="${DOCS_DIR}/05-complete.json"

echo "=== Phase 5: Automation & Access (nc_install v${NC_INSTALL_VERSION}) ==="
echo "Desktop: ${CURRENT_USER} | NC user: ${NC_USER}"
echo "Apache backend: ${BACKEND_HOST}:${BACKEND_PORT}"
echo ""

# Deploy watcher
cat > "${WATCHER_SCRIPT}" << WATCHER
#!/bin/bash
set -euo pipefail
WEB_ROOT="${WEB_ROOT}"
NC_USER="${NC_USER}"
HOME_DIR="${CURRENT_HOME}"
PHP_BIN="${PHP_BIN}"
FOLDERS=(Documents Pictures Music Videos Public Templates Downloads Desktop Backups Notes Projects)

log() { echo "[\$(date '+%F %T')] \$*"; }

command -v inotifywait >/dev/null || { log "Install inotify-tools"; exit 1; }

WATCH_PATHS=()
for d in "\${FOLDERS[@]}"; do
  p="\${HOME_DIR}/\${d}"
  [ -d "\${p}" ] && WATCH_PATHS+=("\${p}")
done

[ "\${#WATCH_PATHS[@]}" -gt 0 ] || { log "No folders to watch"; exit 1; }

log "nc_install_v3 watcher — \${WATCH_PATHS[*]}"

inotifywait -m -r -e create,modify,delete,move,close_write --format '%w%f %e' "\${WATCH_PATHS[@]}" |
while read -r path event; do
  for d in "\${FOLDERS[@]}"; do
    if [[ "\${path}" == "\${HOME_DIR}/\${d}"* ]]; then
      log "Change in \${d}: \${event}"
      sudo -n -u www-data "\${PHP_BIN}" "\${WEB_ROOT}/occ" files:scan "\${NC_USER}" --path="/\${d}" --quiet 2>/dev/null || true
      break
    fi
  done
done
WATCHER

chmod +x "${WATCHER_SCRIPT}"
sudo apt install -y inotify-tools 2>/dev/null || true

# Sync cron + sudoers
nc_install_occ_scan_sudoers "${CURRENT_USER}" "${WEB_ROOT}"
nc_install_sync_cron "${CURRENT_USER}" "${NC_USER}" "${WEB_ROOT}" "${SYNC_INTERVAL}"

# Apache vhost on plan-defined backend
nc_configure_apache_nextcloud_vhost "${WEB_ROOT}" "${PHP_SERIES}" "${BACKEND_HOST}" "${BACKEND_PORT}"

# Tailscale serve
NC_INSTALL_OWNER="${CURRENT_USER}" nc_configure_tailscale_serve "${WEB_ROOT}" "${PHP_BIN}" "${CURRENT_USER}" "${TS_BACKEND}"

# Symlink guardian (repairs mobile-app deletions)
chmod +x "${GUARDIAN_SCRIPT}" 2>/dev/null || true
nc_install_symlink_guardian_cron "${CURRENT_USER}" "${GUARDIAN_SCRIPT}" "${GUARDIAN_INTERVAL}"

sudo -u www-data "${PHP_BIN}" "${WEB_ROOT}/occ" files:scan "${NC_USER}" || true

python3 <<PY
import json
from datetime import datetime, timezone

out = {
  "phase": 5,
  "installer_version": "${NC_INSTALL_VERSION}",
  "timestamp": datetime.now().astimezone().isoformat(),
  "desktop_user": "${CURRENT_USER}",
  "nc_username": "${NC_USER}",
  "watcher_script": "${WATCHER_SCRIPT}",
  "symlink_guardian": "${GUARDIAN_SCRIPT}",
  "apache_backend": "${BACKEND_HOST}:${BACKEND_PORT}",
  "tailscale_backend": "${TS_BACKEND}",
  "sync_cron_minutes": ${SYNC_INTERVAL},
  "symlink_guardian_minutes": ${GUARDIAN_INTERVAL},
  "sync_cron_installed": True,
  "tailscale_serve": "configured",
  "final_scan_done": True,
  "notes": "Start watcher: nohup ${WATCHER_SCRIPT} > $(nc_watch_log) 2>&1 &"
}
with open("${OUTPUT_FILE}", "w") as f:
    json.dump(out, f, indent=2)
PY

echo ""
echo "=== Phase 5 Complete ==="
echo "Start watcher:"
echo "  nohup ${WATCHER_SCRIPT} > $(nc_watch_log) 2>&1 &"
echo "Next: bash phase-06-backup-automation.sh"
echo "================================================================"