#!/usr/bin/env bash
# fix-restic-env.sh — Move restic.env from /root to kraken (sudo wrote to wrong HOME)
#
# Run: sudo bash ~/SovereignAid/scripts/backup/fix-restic-env.sh

set -euo pipefail

OWNER="${SUDO_USER:-kraken}"
DEST="/home/${OWNER}/.config/sovereign/restic.env"
SRC="/root/.config/sovereign/restic.env"

[[ "$(id -u)" -eq 0 ]] || { echo "Run with: sudo bash $0" >&2; exit 1; }

if [[ -f "${DEST}" ]]; then
    echo "OK: ${DEST} already exists"
    chown "${OWNER}:${OWNER}" "${DEST}"
    chmod 0600 "${DEST}"
    exit 0
fi

[[ -f "${SRC}" ]] || { echo "ERROR: ${SRC} not found — run init-restic-repo.sh" >&2; exit 1; }

install -d -m 0700 -o "${OWNER}" -g "${OWNER}" "$(dirname "${DEST}")"
install -m 0600 -o "${OWNER}" -g "${OWNER}" "${SRC}" "${DEST}"
echo "Migrated ${SRC} → ${DEST}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
bash "${SCRIPT_DIR}/fix-restic-permissions.sh"

echo "Run: bash ~/SovereignAid/scripts/backup/run-smadp-backup.sh"