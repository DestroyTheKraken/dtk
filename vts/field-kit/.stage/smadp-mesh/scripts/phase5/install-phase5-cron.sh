#!/usr/bin/env bash
# install-phase5-cron.sh — Daily 8am health report + weekly backup cron
#
# Run on um690: sudo bash ~/SovereignAid/scripts/phase5/install-phase5-cron.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO="$(cd "${SCRIPT_DIR}/../.." && pwd)"
CRON_FILE="/etc/cron.d/smadp-phase5"
LOG_DIR="/var/log/smadp"
OWNER="${SUDO_USER:-kraken}"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run on um690" >&2; exit 1; }

install -d -m 0755 "${LOG_DIR}"
touch "${LOG_DIR}/health-report.log" "${LOG_DIR}/backup.log"
chmod 0644 "${LOG_DIR}"/*.log 2>/dev/null || true

cat > "${CRON_FILE}" << EOF
# SMADP Phase 5 — health report + backup (America/Los_Angeles)
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin
CRON_TZ=America/Los_Angeles
0 8 * * * ${OWNER} ${REPO}/scripts/phase5/daily-health-report.sh >> ${LOG_DIR}/health-report.log 2>&1
0 3 * * 0 ${OWNER} ${REPO}/scripts/backup/run-smadp-backup.sh >> ${LOG_DIR}/backup.log 2>&1
EOF
chmod 0644 "${CRON_FILE}"

echo "Installed ${CRON_FILE}"
echo "  Health report: daily 08:00 PT"
echo "  Backup:        Sunday 03:00 PT"
echo "  Logs: ${LOG_DIR}/"