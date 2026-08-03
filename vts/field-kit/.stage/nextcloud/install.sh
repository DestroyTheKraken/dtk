#!/bin/bash
#
# nc_install_v3 — canonical one-command installer (field / customer SOP)
#
# Usage (from kit directory or after USB extract):
#   bash install.sh
#
# Debug (one phase at a time):
#   bash phase-01-scan-host.sh
#   bash phase-02-prereqs.sh
#   ...
#
# Automation only (skip prompts — not for live customer installs):
#   NC_USERNAME=client NC_ADMIN_PASSWORD='choose-strong-password' bash install.sh
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export NC_INSTALL_SCRIPT_DIR="${SCRIPT_DIR}"
# shellcheck source=nc-common.sh
source "${SCRIPT_DIR}/nc-common.sh"

PHASES=(
  phase-01-scan-host.sh
  phase-02-prereqs.sh
  phase-03-nextcloud-core.sh
  phase-04-user-symlinks-acls.sh
  phase-05-automation.sh
  phase-06-backup-automation.sh
)

echo "================================================================"
echo "  nc-lin-cs — Nextcloud Linux hub installer v${NC_INSTALL_VERSION}"
echo "================================================================"
echo ""
echo "  Phase 1 will prompt for:"
echo "    • Nextcloud username (default: $(whoami))"
echo "    • Login password (Enter = auto-generate)"
echo ""
echo "  Phases 2–6 use sudo. You may be prompted once for your"
echo "  Linux password; it is cached for the rest of this session."
echo ""
echo "  Kit directory: ${SCRIPT_DIR}"
echo "================================================================"
echo ""

if ! sudo -n true 2>/dev/null; then
  echo "Authenticate sudo to continue..."
  sudo -v
  # Keep sudo timestamp fresh during long apt/occ steps
  while true; do
    sleep 60
    sudo -n true 2>/dev/null || break
  done &
  SUDO_KEEPALIVE_PID=$!
  trap 'kill ${SUDO_KEEPALIVE_PID} 2>/dev/null || true' EXIT
fi

step=0
total=${#PHASES[@]}
for phase in "${PHASES[@]}"; do
  step=$((step + 1))
  echo ""
  echo ">>> Phase ${step}/${total}: ${phase}"
  echo "----------------------------------------------------------------"
  bash "${SCRIPT_DIR}/${phase}"
done

echo ""
echo ">>> Post-install verification"
bash "${SCRIPT_DIR}/verify-install.sh" || true

echo ""
echo ">>> Starting file watcher"
nc_start_watcher "${SCRIPT_DIR}" || nc_log "Start manually: nohup ${SCRIPT_DIR}/watch-and-scan.sh > $(nc_watch_log) 2>&1 &"

echo ""
echo "================================================================"
echo "  Install complete"
echo "================================================================"
echo ""
echo "  Watcher log: $(nc_watch_log)"
echo "    tail -f $(nc_watch_log)"
echo ""
echo "  Login credentials:"
echo "    phase-docs/03-nextcloud-core.json"
echo ""
if command -v tailscale >/dev/null; then
  TS_HOST="$(tailscale status --json 2>/dev/null | python3 -c 'import sys,json; d=json.load(sys.stdin); print(d.get("Self",{}).get("DNSName","").rstrip("."))' 2>/dev/null || true)"
  [ -n "${TS_HOST}" ] && echo "  URL: https://${TS_HOST}"
fi
echo ""
echo "  Remove kit from hub after install (optional; keep for demo/debug):"
echo "    rm -rf ${SCRIPT_DIR}"
echo "================================================================"
