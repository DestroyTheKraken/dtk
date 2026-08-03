#!/usr/bin/env bash
# install-tailscale-tls-cron.sh — Daily root cron for Tailscale TLS renewal
#
# Run on um690: sudo bash ~/SovereignAid/scripts/phase2/install-tailscale-tls-cron.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RENEW_SCRIPT="${SCRIPT_DIR}/renew-tailscale-tls-if-needed.sh"
CRON_FILE="/etc/cron.d/smadp-tailscale-tls-renew"
LOG_DIR="/var/log/smadp"
LOG_FILE="${LOG_DIR}/tailscale-tls-renew.log"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run on um690" >&2; exit 1; }
[[ -x "${RENEW_SCRIPT}" ]] || chmod +x "${RENEW_SCRIPT}"
[[ -x "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh" ]] || chmod +x "${SCRIPT_DIR}/sync-tailscale-tls-secret.sh"

install -d -m 0755 "${LOG_DIR}"
install -m 0644 /dev/null "${LOG_FILE}" 2>/dev/null || touch "${LOG_FILE}"
chmod 0644 "${LOG_FILE}"

# Daily 03:15 — renew only when <=30 days remain
cat > "${CRON_FILE}" << EOF
# SMADP Tailscale TLS renewal for Nextcloud (um690)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
15 3 * * * root ${RENEW_SCRIPT} >> ${LOG_FILE} 2>&1
EOF
chmod 0644 "${CRON_FILE}"

tailscale set --operator=root 2>/dev/null || true

echo "Installed ${CRON_FILE}"
echo "  Schedule: daily 03:15 (renews when <=30 days remain)"
echo "  Log: ${LOG_FILE}"
echo ""
echo "Test now: sudo bash ${RENEW_SCRIPT}"