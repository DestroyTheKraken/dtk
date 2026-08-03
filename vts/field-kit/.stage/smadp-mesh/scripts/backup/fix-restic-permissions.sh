#!/usr/bin/env bash
# fix-restic-permissions.sh — kraken must own /mnt/systems_admin/restic (sudo init left root-only)
#
# Run: sudo bash ~/SovereignAid/scripts/backup/fix-restic-permissions.sh

set -euo pipefail

OWNER="${SUDO_USER:-kraken}"
RESTIC_BASE="/mnt/systems_admin/restic"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }
[[ "$(hostname -s)" == "um690" ]] || { echo "Run on um690" >&2; exit 1; }
mountpoint -q /mnt/systems_admin || { echo "ERROR: /mnt/systems_admin not mounted" >&2; exit 1; }

install -d -m 0755 -o "${OWNER}" -g "${OWNER}" "${RESTIC_BASE}"
install -d -m 0750 -o "${OWNER}" -g "${OWNER}" "${RESTIC_BASE}/staging"
if [[ -d "${RESTIC_BASE}/smadp" ]]; then
    chown -R "${OWNER}:${OWNER}" "${RESTIC_BASE}/smadp"
    chmod 700 "${RESTIC_BASE}/smadp"
fi

echo "Fixed ownership: ${RESTIC_BASE} → ${OWNER}"
ls -la "${RESTIC_BASE}"
echo ""
echo "Run: bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh"