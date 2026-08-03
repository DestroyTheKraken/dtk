#!/bin/bash
# Post-install verification for nc_install_v3.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

WEB_ROOT="${WEB_ROOT:-/var/www/nextcloud}"
NC_USER=$(nc_resolve_nc_user "$(whoami)" "/var/lib/nextcloud/data" "$(nc_docs_dir)")
fail=0
notes=()

check() {
  if eval "$2" >/dev/null 2>&1; then
    nc_log "OK   $1"
    notes+=("$1: OK")
  else
    nc_log "FAIL $1"
    notes+=("$1: FAIL")
    fail=1
  fi
}

nc_log "nc_install_v3 verify — NC user: ${NC_USER}"

check "NC username resolved" "[ -n '${NC_USER}' ]"
check "Phase 1 install_plan present" "[ -f '$(nc_docs_dir)/01-host-scan.json' ] && python3 -c \"import json; json.load(open('$(nc_docs_dir)/01-host-scan.json'))['install_plan']\""
check "Sync cron entry" "crontab -l | grep -q 'files:scan'"
check "Symlink guardian cron" "crontab -l | grep -q symlink-guardian"

if crontab -l 2>/dev/null | grep -q 'backup-hub-to-staging'; then
  check "Backup cron entry" "true"
else
  nc_log "SKIP backup cron (run phase-06)"
fi

if command -v tailscale >/dev/null; then
  check "Tailscale serve" "tailscale serve status"
else
  nc_log "SKIP Tailscale (not installed)"
fi

check "Apache :8080 vhost" "grep -q '127.0.0.1:8080' /etc/apache2/sites-available/nextcloud.conf 2>/dev/null || curl -sf http://127.0.0.1:8080/status.php"

PHP_BIN="$(nc_php_bin 2>/dev/null || echo php)"
check "outward symlinks enabled" "
  sudo -n grep -qE \"'localstorage\\.allowsymlinks'\\s*=>\\s*true|'follow_symlinks'\\s*=>\\s*true\" ${WEB_ROOT}/config/config.php 2>/dev/null \
  || sudo -n -u www-data ${PHP_BIN} ${WEB_ROOT}/occ config:system:get localstorage.allowsymlinks 2>/dev/null | grep -qi true \
  || sudo -n -u www-data ${PHP_BIN} ${WEB_ROOT}/occ config:system:get follow_symlinks 2>/dev/null | grep -qi true
"

if pgrep -f inotifywait >/dev/null; then
  check "Watcher running" "true"
else
  nc_log "SKIP watcher (start: nohup ${SCRIPT_DIR}/watch-and-scan.sh > $(nc_watch_log) &)"
fi

HOST_ID="${NC_TEST_HOST_ID:-test-$(hostname -s)}"
STATUS="pass"
[ "$fail" -eq 0 ] || STATUS="partial"
nc_record_test_iteration "${HOST_ID}" "${STATUS}" "$(printf '%s; ' "${notes[@]}")"

if [ -f "/etc/sudoers.d/nc-install-temp-$(whoami)" ]; then
  bash "${SCRIPT_DIR}/remove-temp-sudo.sh" "$(whoami)" 2>/dev/null || true
  nc_log "Removed temporary install sudoers"
fi

if [ "$fail" -eq 0 ]; then
  nc_log "PASS: install verification"
else
  nc_log "WARN: some checks failed"
fi
exit "$fail"
